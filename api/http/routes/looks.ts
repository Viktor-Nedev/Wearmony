import { Hono } from 'hono';
import { z } from 'zod';
import type { EventRecord, ItemRecord, ItemType, LookRecord, ParticipantRecord } from '../../domain/types.js';
import { advanceLook, resetFailedStep } from '../../render/pipeline.js';
import { previewLooks } from '../../render/previews.js';
import type { Services } from '../../services.js';
import { HttpError, loadParticipantEvent, parseJson, requireUser, type AppEnv } from '../context.js';
import { iso, lookTotal, renderDto, signAll } from '../dto.js';

export const looks = new Hono<AppEnv>();

const optionalId = z.string().uuid().nullable().optional();
const SetLook = z.object({ garmentId: optionalId, makeupId: optionalId, hairId: optionalId });

export function emptyLook(eventId: string, userId: string, now: number): LookRecord {
  return {
    eventId,
    userId,
    garmentId: null,
    makeupId: null,
    hairId: null,
    locked: false,
    renderRequested: false,
    updatedAt: iso(now),
  };
}

export async function itemMap(services: Services, eventId: string): Promise<Map<string, ItemRecord>> {
  return new Map((await services.repo.listItems(eventId)).map((item) => [item.id, item]));
}

/** The caller's look with prices and the (advanced) render state. */
async function lookResponse(services: Services, event: EventRecord, participant: ParticipantRecord) {
  const [look, items] = await Promise.all([services.repo.getLook(event.id, participant.userId), itemMap(services, event.id)]);
  const state = await advanceLook(services.pipeline, event, participant, look, items);
  const [resultUrl] = await signAll(services.storage, [state.resultPath]);
  const current = look ?? emptyLook(event.id, participant.userId, services.now());
  return {
    garmentId: current.garmentId,
    makeupId: current.makeupId,
    hairId: current.hairId,
    locked: current.locked,
    total: lookTotal(look, items),
    currency: event.currency,
    render: renderDto(state, resultUrl ?? null),
  };
}

looks.get('/events/:eventId/look', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  return c.json(await lookResponse(c.var.services, event, participant));
});

looks.put('/events/:eventId/look', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const body = await parseJson(c, SetLook);
  const { repo, now } = c.var.services;
  const current = (await repo.getLook(event.id, participant.userId)) ?? emptyLook(event.id, participant.userId, now());
  if (current.locked) throw new HttpError(423, 'look_locked', 'Unlock your look before changing it.');

  const items = await itemMap(c.var.services, event.id);
  const pick = (id: string | null | undefined, type: ItemType, fallback: string | null) => {
    if (id === undefined) return fallback;
    if (id === null) return null;
    if (items.get(id)?.type !== type) throw new HttpError(400, 'invalid_item', `That is not a ${type} from this event.`);
    return id;
  };
  const updated: LookRecord = {
    ...current,
    garmentId: pick(body.garmentId, 'garment', current.garmentId),
    makeupId: pick(body.makeupId, 'makeup', current.makeupId),
    hairId: pick(body.hairId, 'hair', current.hairId),
    // A changed look is never rendered until the participant asks again.
    renderRequested: false,
    updatedAt: iso(now()),
  };
  await repo.upsertLook(updated);
  return c.json(await lookResponse(c.var.services, event, participant));
});

looks.post('/events/:eventId/look/render', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const body = await parseJson(c, z.object({ retry: z.boolean().optional() }).default({}));
  const services = c.var.services;
  if (!participant.photoPath) throw new HttpError(409, 'photo_required', 'Upload your photo first.');

  const look = await services.repo.getLook(event.id, participant.userId);
  if (!look || (!look.garmentId && !look.makeupId && !look.hairId)) {
    throw new HttpError(409, 'look_empty', 'Pick at least one item first.');
  }
  if (body.retry) await resetFailedStep(services.pipeline, event, participant, look, await itemMap(services, event.id));
  await services.repo.upsertLook({ ...look, renderRequested: true });
  return c.json(await lookResponse(services, event, participant));
});

/**
 * The looks this participant has already seen on their current photo, newest
 * first. Every step is cached, so wearing one again previews at no cost.
 */
looks.get('/events/:eventId/me/previews', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  if (!participant.photoPath) return c.json([]);
  const services = c.var.services;
  const [renders, items, current] = await Promise.all([
    services.repo.listRenders(event.id),
    itemMap(services, event.id),
    services.repo.getLook(event.id, participant.userId),
  ]);
  const found = previewLooks(renders, participant.userId, participant.photoPath);
  const urls = await signAll(services.storage, found.map((look) => look.resultPath));
  const summary = (id: string | null) => {
    const item = id ? items.get(id) : undefined;
    return item
      ? { id: item.id, name: item.name, price: item.price, colorHex: item.colorHex ?? item.dominantColors?.[0]?.hex ?? null }
      : null;
  };
  return c.json(
    found.map((look, i) => ({
      garment: summary(look.garmentId),
      makeup: summary(look.makeupId),
      hair: summary(look.hairId),
      imageUrl: urls[i] ?? null,
      at: look.at,
      current:
        current !== null &&
        current.garmentId === look.garmentId &&
        current.makeupId === look.makeupId &&
        current.hairId === look.hairId,
    })),
  );
});

looks.post('/events/:eventId/look/lock', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const body = await parseJson(c, z.object({ locked: z.boolean() }));
  const { repo, now } = c.var.services;
  const look = (await repo.getLook(event.id, participant.userId)) ?? emptyLook(event.id, participant.userId, now());
  if (body.locked && !look.garmentId) throw new HttpError(409, 'look_empty', 'Pick an outfit before locking your look.');
  await repo.upsertLook({ ...look, locked: body.locked, updatedAt: iso(now()) });
  return c.json(await lookResponse(c.var.services, event, participant));
});
