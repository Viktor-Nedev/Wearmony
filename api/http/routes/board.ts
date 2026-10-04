import { createHash, randomBytes } from 'node:crypto';
import { Hono } from 'hono';
import { z } from 'zod';
import { withRenderCache } from '../../data/render-cache.js';
import { recentActivity } from '../../domain/activity.js';
import type { EventRecord, ItemRecord, LookRecord, ParticipantRecord } from '../../domain/types.js';
import { checkDressCode } from '../../harmony/dresscode.js';
import { computeHarmony, type HarmonyPersonInput } from '../../harmony/engine.js';
import { pickTarget, suggestFixes } from '../../harmony/suggest.js';
import { summarizeUnits } from '../../ledger/ledger.js';
import { advanceLook } from '../../render/pipeline.js';
import type { Services } from '../../services.js';
import { HttpError, loadEvent, loadOrganizerEvent, parseJson, requireUser, type AppEnv } from '../context.js';
import { eventDto, iso, lookTotal, renderDto, signAll } from '../dto.js';
import { itemMap } from './looks.js';

export const board = new Hono<AppEnv>();

function summary(item: ItemRecord | undefined) {
  return item
    ? { id: item.id, name: item.name, price: item.price, colorHex: item.colorHex ?? item.dominantColors?.[0]?.hex ?? null }
    : null;
}

export function harmonyInputs(
  participants: ParticipantRecord[],
  looks: Map<string, LookRecord>,
  items: Map<string, ItemRecord>,
): HarmonyPersonInput[] {
  return participants.map((p) => {
    const look = looks.get(p.userId);
    const item = (id: string | null | undefined) => (id ? items.get(id) : undefined);
    return {
      id: p.userId,
      name: p.displayName,
      partnerId: p.pairWith,
      outfit: item(look?.garmentId)?.dominantColors ?? null,
      lips: item(look?.makeupId)?.colorHex ?? null,
      hair: item(look?.hairId)?.colorHex ?? null,
    };
  });
}

async function loadGroup(services: Services, event: EventRecord) {
  const [participants, lookList, items, renders] = await Promise.all([
    services.repo.listParticipants(event.id),
    services.repo.listLooks(event.id),
    itemMap(services, event.id),
    services.repo.listRenders(event.id),
  ]);
  return { participants, looks: new Map(lookList.map((l) => [l.userId, l])), items, renders };
}

export async function buildBoard(services: Services, event: EventRecord, viewerId: string) {
  const { participants, looks, items, renders } = await loadGroup(services, event);
  const pipeline = { ...services.pipeline, repo: withRenderCache(services.repo, renders) };

  // Advancing here keeps renders moving even if a participant closed the app.
  const states = await Promise.all(
    participants.map((p) => advanceLook(pipeline, event, p, looks.get(p.userId) ?? null, items)),
  );
  const urls = await signAll(services.storage, [
    ...participants.map((p) => p.photoPath),
    ...states.map((s) => s.resultPath),
  ]);

  const totals = participants.map((p) => lookTotal(looks.get(p.userId) ?? null, items));
  const total = Math.round(totals.reduce((sum, t) => sum + t, 0) * 100) / 100;
  const units = summarizeUnits(await pipeline.repo.listRenders(event.id));

  const rows = participants.map((p, i) => {
    const look = looks.get(p.userId) ?? null;
    return {
      userId: p.userId,
      displayName: p.displayName,
      pairWith: p.pairWith,
      pose: p.pose,
      isMe: p.userId === viewerId,
      hasPhoto: Boolean(p.photoPath),
      photoUrl: urls[i] ?? null,
      look: {
        garment: summary(look?.garmentId ? items.get(look.garmentId) : undefined),
        makeup: summary(look?.makeupId ? items.get(look.makeupId) : undefined),
        hair: summary(look?.hairId ? items.get(look.hairId) : undefined),
        locked: look?.locked ?? false,
        total: totals[i]!,
      },
      overBudget: event.budgetPerPerson !== null && totals[i]! > event.budgetPerPerson,
      render: renderDto(states[i]!, urls[participants.length + i] ?? null),
    };
  });

  return {
    participants: rows,
    participantCount: participants.length,
    renderedCount: states.filter((s) => s.status === 'success').length,
    lockedCount: rows.filter((r) => r.look.locked).length,
    budget: {
      currency: event.currency,
      perPersonCap: event.budgetPerPerson,
      totalCap: event.budgetTotal,
      total,
      overTotal: event.budgetTotal !== null && total > event.budgetTotal,
      overBudgetCount: rows.filter((r) => r.overBudget).length,
    },
    units: {
      used: units.event,
      cap: services.env.LEDGER_CAP_PER_EVENT,
      perParticipantCap: services.env.LEDGER_CAP_PER_PARTICIPANT,
      mode: event.demo ? 'demo' : services.pipeline.provider.mode,
    },
    harmony: computeHarmony(harmonyInputs(participants, looks, items)),
    dressCode: checkDressCode(harmonyInputs(participants, looks, items), event.dressCode),
    activity: recentActivity(participants, looks, items, renders),
  };
}

board.get('/events/:eventId/board', requireUser, async (c) => {
  const { event, participant, isOrganizer } = await loadEvent(c, c.req.param('eventId'));
  const data = await buildBoard(c.var.services, event, c.var.userId);
  return c.json({ event: eventDto(event, { isOrganizer, isParticipant: Boolean(participant) }), ...data });
});

board.get('/events/:eventId/harmony', requireUser, async (c) => {
  const { event } = await loadEvent(c, c.req.param('eventId'));
  const { participants, looks, items } = await loadGroup(c.var.services, event);
  return c.json(computeHarmony(harmonyInputs(participants, looks, items)));
});

/**
 * Catalogue swaps that would remove a near-miss: the group's weakest one, with
 * ?user=<id> the weakest one involving that person, and with ?user=<id>&with=<id>
 * the near-miss between those two. Same engine, no model opinions.
 */
board.get('/events/:eventId/harmony/suggestions', requireUser, async (c) => {
  const { event } = await loadEvent(c, c.req.param('eventId'));
  const { participants, looks, items } = await loadGroup(c.var.services, event);
  const people = harmonyInputs(participants, looks, items);
  const target = pickTarget(
    computeHarmony(people).findings,
    c.req.query('user') || undefined,
    c.req.query('with') || undefined,
  );
  if (!target) return c.json({ target: null, suggestions: [] });

  const suggestions = suggestFixes({
    people,
    looks: new Map(
      [...looks.values()].map((l) => [
        l.userId,
        { garmentId: l.garmentId, makeupId: l.makeupId, hairId: l.hairId, locked: l.locked },
      ]),
    ),
    items: [...items.values()].map((item) => ({
      id: item.id,
      type: item.type,
      name: item.name,
      price: item.price,
      category: item.category,
      dominantColors: item.dominantColors,
      colorHex: item.colorHex,
    })),
    perPersonCap: event.budgetPerPerson,
    target,
  });
  const urls = await signAll(
    c.var.services.storage,
    suggestions.map((s) => items.get(s.itemId)?.imagePath ?? null),
  );
  return c.json({
    target,
    suggestions: suggestions.map((s, i) => ({ ...s, imageUrl: urls[i] ?? null })),
  });
});

board.post('/events/:eventId/harmony/explain', requireUser, async (c) => {
  const { event } = await loadEvent(c, c.req.param('eventId'));
  const { language } = await parseJson(c, z.object({ language: z.enum(['en', 'bg']).default('en') }));
  const explainer = c.var.services.explainer;
  if (!explainer) throw new HttpError(503, 'explain_unavailable', 'Plain-language summaries are not configured.');
  const { participants, looks, items } = await loadGroup(c.var.services, event);
  const report = computeHarmony(harmonyInputs(participants, looks, items));
  if (report.findings.length === 0) throw new HttpError(409, 'nothing_to_explain', 'Add outfits to compare first.');
  try {
    return c.json({ text: await explainer.explain(report, language), model: explainer.model });
  } catch (error) {
    console.error('explain failed', error);
    throw new HttpError(503, 'explain_failed', 'The summary could not be written right now.');
  }
});

const CreateLink = z.object({
  scope: z.enum(['look', 'hair', 'catalogue']),
  userId: z.string().uuid().optional(),
  vendorName: z.string().trim().min(1).max(60).optional(),
  hours: z.number().int().min(1).max(720).default(168),
});

export const hashToken = (token: string) => createHash('sha256').update(token).digest('hex');

board.post('/events/:eventId/vendor-links', requireUser, async (c) => {
  const { event, isOrganizer } = await loadEvent(c, c.req.param('eventId'));
  const body = await parseJson(c, CreateLink);
  const { repo, now } = c.var.services;

  let userId: string | null = null;
  if (body.scope === 'catalogue') {
    if (!isOrganizer) throw new HttpError(403, 'organizer_only', 'Only the organizer can invite vendors to the catalogue.');
  } else {
    userId = body.userId ?? c.var.userId;
    if (userId !== c.var.userId && !isOrganizer) throw new HttpError(403, 'forbidden', 'You can only share your own look.');
    if (!(await repo.getParticipant(event.id, userId))) throw new HttpError(404, 'participant_not_found', 'That person is not in this event.');
  }

  const token = randomBytes(24).toString('base64url');
  const expiresAt = iso(now() + body.hours * 3600_000);
  await repo.createVendorLink({
    tokenHash: hashToken(token),
    eventId: event.id,
    userId,
    scope: body.scope,
    vendorName: body.vendorName ?? null,
    createdBy: c.var.userId,
    expiresAt,
    createdAt: iso(now()),
  });
  return c.json({ token, path: `/v/${token}`, scope: body.scope, expiresAt }, 201);
});

board.get('/events/:eventId/vendor-links', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const links = await c.var.services.repo.listVendorLinks(event.id);
  return c.json(
    links.map((l) => ({
      id: l.tokenHash,
      scope: l.scope,
      userId: l.userId,
      vendorName: l.vendorName,
      expiresAt: l.expiresAt,
      expired: Date.parse(l.expiresAt) < c.var.services.now(),
    })),
  );
});

board.delete('/events/:eventId/vendor-links/:id', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const link = await c.var.services.repo.getVendorLink(c.req.param('id'));
  if (!link || link.eventId !== event.id) throw new HttpError(404, 'link_not_found', 'This link does not exist.');
  await c.var.services.repo.deleteVendorLink(link.tokenHash);
  return c.body(null, 204);
});
