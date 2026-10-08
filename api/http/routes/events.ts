import { createHash, randomInt, randomUUID } from 'node:crypto';
import { Hono } from 'hono';
import { z } from 'zod';
import type { Repository } from '../../data/repository.js';
import { seedDemoEvent, type DemoKind } from '../../demo/seed.js';
import type { EventRecord, ParticipantRecord } from '../../domain/types.js';
import { checkPhotoQuality } from '../../harmony/checks.js';
import { readImageInfo } from '../../lib/image-size.js';
import { normalizeImage } from '../../lib/normalize-image.js';
import type { Services } from '../../services.js';
import { mediaPaths } from '../../storage/storage.js';
import {
  HttpError,
  loadEvent,
  loadOrganizerEvent,
  loadParticipantEvent,
  parseJson,
  readImageBody,
  requireUser,
  type AppEnv,
} from '../context.js';
import { eventDto, iso, participantDto, signAll } from '../dto.js';

export const events = new Hono<AppEnv>();

const JOIN_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const money = z.number().nonnegative().max(1_000_000).nullable().optional();
const displayName = z.string().trim().min(1).max(40);
/** A calendar day, YYYY-MM-DD, that exists. */
const eventDate = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/)
  .refine((day) => {
    // Date rolls 30 February over to March, so a real day must survive the round trip.
    const parsed = new Date(`${day}T00:00:00Z`);
    return !Number.isNaN(parsed.getTime()) && parsed.toISOString().startsWith(day);
  }, 'Not a real date.')
  .nullable()
  .optional();

/** Up to four #RRGGBB colors, stored upper-case and without repeats. */
const dressCode = z
  .array(z.string().regex(/^#[0-9a-fA-F]{6}$/))
  .max(4)
  .transform((colors) => [...new Set(colors.map((color) => color.toUpperCase()))])
  .optional();

const CreateEvent = z.object({
  name: z.string().trim().min(1).max(80),
  template: z.enum(['prom', 'theatre', 'group']),
  budgetPerPerson: money,
  budgetTotal: money,
  currency: z.string().regex(/^[A-Z]{3}$/).default('EUR'),
  eventDate,
  lockBy: eventDate,
  dressCode,
});

const UpdateEvent = z.object({
  name: z.string().trim().min(1).max(80).optional(),
  budgetPerPerson: money,
  budgetTotal: money,
  eventDate,
  lockBy: eventDate,
  dressCode,
});

/** Looks are due on or before the event day (YYYY-MM-DD compares as text). */
function checkLockBy(eventDay: string | null, lockBy: string | null) {
  if (eventDay && lockBy && lockBy > eventDay) {
    throw new HttpError(400, 'lock_after_event', 'Looks must be due on or before the day of the event.');
  }
}

const Join = z.object({ code: z.string().min(4).max(12), displayName });

const UpdateMe = z.object({
  displayName: displayName.optional(),
  pose: z.enum(['standing', 'seated']).optional(),
  pairWith: z.string().uuid().nullable().optional(),
});

export function normalizeJoinCode(code: string) {
  return code.toUpperCase().replace(/[^A-Z0-9]/g, '');
}

async function uniqueJoinCode(repo: Repository): Promise<string> {
  for (let attempt = 0; attempt < 20; attempt++) {
    const code = Array.from({ length: 6 }, () => JOIN_ALPHABET[randomInt(JOIN_ALPHABET.length)]).join('');
    if (!(await repo.getEventByCode(code))) return code;
  }
  throw new Error('Could not find a free join code');
}

events.post('/events', requireUser, async (c) => {
  const body = await parseJson(c, CreateEvent);
  const { repo, now } = c.var.services;
  const event: EventRecord = {
    id: randomUUID(),
    name: body.name,
    template: body.template,
    organizerId: c.var.userId,
    joinCode: await uniqueJoinCode(repo),
    budgetPerPerson: body.budgetPerPerson ?? null,
    budgetTotal: body.budgetTotal ?? null,
    currency: body.currency,
    eventDate: body.eventDate ?? null,
    lockBy: body.lockBy ?? null,
    dressCode: body.dressCode ?? [],
    demo: false,
    createdAt: iso(now()),
  };
  checkLockBy(event.eventDate, event.lockBy);
  await repo.createEvent(event);
  return c.json(eventDto(event, { isOrganizer: true, isParticipant: false }), 201);
});

/**
 * One demo event of each kind per visitor: opening it again returns the existing
 * one. ?template=theatre opens the school theatre cast instead of the prom.
 */
events.post('/demo', requireUser, async (c) => {
  const { repo } = c.var.services;
  const kind: DemoKind = c.req.query('template') === 'theatre' ? 'theatre' : 'prom';
  const existing = (await repo.listEventsForUser(c.var.userId)).find(
    (event) => event.demo && event.organizerId === c.var.userId && event.template === kind,
  );
  if (existing) {
    const participant = await repo.getParticipant(existing.id, c.var.userId);
    return c.json(eventDto(existing, { isOrganizer: true, isParticipant: Boolean(participant) }), 200);
  }
  const event = await seedDemoEvent(c.var.services, c.var.userId, kind);
  return c.json(eventDto(event, { isOrganizer: true, isParticipant: true }), 201);
});

events.get('/me/events', requireUser, async (c) => {
  const { repo } = c.var.services;
  const list = await repo.listEventsForUser(c.var.userId);
  const result = await Promise.all(
    list.map(async (event) => {
      const participant = await repo.getParticipant(event.id, c.var.userId);
      return eventDto(event, { isOrganizer: event.organizerId === c.var.userId, isParticipant: Boolean(participant) });
    }),
  );
  return c.json(result);
});

/** Leaves every event the caller joined and deletes all their photos, looks and renders. */
events.delete('/me', requireUser, async (c) => {
  const { repo } = c.var.services;
  let left = 0;
  for (const event of await repo.listEventsForUser(c.var.userId)) {
    if (await repo.getParticipant(event.id, c.var.userId)) {
      await removeParticipant(c.var.services, event.id, c.var.userId);
      left++;
    }
  }
  return c.json({ left });
});

events.get('/events/:eventId', requireUser, async (c) => {
  const { event, participant, isOrganizer } = await loadEvent(c, c.req.param('eventId'));
  const [photoUrl] = await signAll(c.var.services.storage, [participant?.photoPath]);
  return c.json({
    ...eventDto(event, { isOrganizer, isParticipant: Boolean(participant) }),
    me: participant ? participantDto(participant, photoUrl ?? null) : null,
  });
});

events.patch('/events/:eventId', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const body = await parseJson(c, UpdateEvent);
  checkLockBy(
    body.eventDate !== undefined ? body.eventDate : event.eventDate,
    body.lockBy !== undefined ? body.lockBy : event.lockBy,
  );
  await c.var.services.repo.updateEvent(event.id, body);
  const updated = (await c.var.services.repo.getEvent(event.id))!;
  const participant = await c.var.services.repo.getParticipant(event.id, c.var.userId);
  return c.json(eventDto(updated, { isOrganizer: true, isParticipant: Boolean(participant) }));
});

/** Deletes the event with every photo, render, look and link. */
events.delete('/events/:eventId', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  await c.var.services.storage.removePrefix(mediaPaths.eventPrefix(event.id));
  await c.var.services.repo.deleteEvent(event.id);
  return c.body(null, 204);
});

events.get('/join/:code', async (c) => {
  const event = await c.var.services.repo.getEventByCode(normalizeJoinCode(c.req.param('code')));
  if (!event) throw new HttpError(404, 'event_not_found', 'No event uses this code.');
  return c.json({ name: event.name, template: event.template, demo: event.demo });
});

events.post('/join', requireUser, async (c) => {
  const body = await parseJson(c, Join);
  const { repo, now } = c.var.services;
  const event = await repo.getEventByCode(normalizeJoinCode(body.code));
  if (!event) throw new HttpError(404, 'event_not_found', 'No event uses this code.');
  const existing = await repo.getParticipant(event.id, c.var.userId);
  const participant: ParticipantRecord = existing
    ? { ...existing, displayName: body.displayName }
    : {
        eventId: event.id,
        userId: c.var.userId,
        displayName: body.displayName,
        pairWith: null,
        photoPath: null,
        photoHash: null,
        photoQuality: null,
        pose: null,
        consentAt: null,
        joinedAt: iso(now()),
      };
  await repo.upsertParticipant(participant);
  return c.json({ eventId: event.id }, existing ? 200 : 201);
});

events.patch('/events/:eventId/me', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const body = await parseJson(c, UpdateMe);
  const { repo } = c.var.services;
  const updated: ParticipantRecord = {
    ...participant,
    displayName: body.displayName ?? participant.displayName,
    pose: body.pose ?? participant.pose,
  };

  if (body.pairWith !== undefined && body.pairWith !== participant.pairWith) {
    if (body.pairWith === participant.userId) throw new HttpError(400, 'invalid_partner', 'You cannot pair with yourself.');
    const partner = body.pairWith ? await repo.getParticipant(event.id, body.pairWith) : null;
    if (body.pairWith && !partner) throw new HttpError(404, 'partner_not_found', 'That person is not in this event.');
    // Pairs are mutual: unlink the old partner, link the new one if they are free.
    if (participant.pairWith) {
      const old = await repo.getParticipant(event.id, participant.pairWith);
      if (old?.pairWith === participant.userId) await repo.upsertParticipant({ ...old, pairWith: null });
    }
    if (partner && (partner.pairWith === null || partner.pairWith === participant.userId)) {
      await repo.upsertParticipant({ ...partner, pairWith: participant.userId });
    }
    updated.pairWith = body.pairWith;
  }

  await repo.upsertParticipant(updated);
  const [photoUrl] = await signAll(c.var.services.storage, [updated.photoPath]);
  return c.json(participantDto(updated, photoUrl ?? null));
});

events.post('/events/:eventId/me/consent', requireUser, async (c) => {
  const { participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const updated = { ...participant, consentAt: participant.consentAt ?? iso(c.var.services.now()) };
  await c.var.services.repo.upsertParticipant(updated);
  const [photoUrl] = await signAll(c.var.services.storage, [updated.photoPath]);
  return c.json(participantDto(updated, photoUrl ?? null));
});

/** Blocking photo problems: try-on engines reject these outright. The rest are advice. */
const BLOCKING_ISSUES = new Set(['too_small', 'unusual_ratio']);

events.put('/events/:eventId/me/photo', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const { repo, storage } = c.var.services;
  if (!participant.consentAt) throw new HttpError(403, 'consent_required', 'Please confirm the consent screen first.');
  const pose = c.req.query('pose') ?? participant.pose;
  if (pose !== 'standing' && pose !== 'seated') {
    throw new HttpError(400, 'pose_required', 'Tell us whether the photo is standing or seated.');
  }

  const raw = await readImageBody(c);
  if (!readImageInfo(raw)) throw new HttpError(415, 'unsupported_image', 'Upload a JPG or PNG image.');
  let normalized;
  try {
    normalized = await normalizeImage(raw, 2048);
  } catch {
    throw new HttpError(415, 'unsupported_image', 'This image could not be read.');
  }

  const quality = await checkPhotoQuality(normalized.bytes);
  if (quality.issues.some((issue) => BLOCKING_ISSUES.has(issue))) {
    throw new HttpError(422, 'photo_rejected', 'This photo cannot be used for try-on.', quality);
  }

  // Replacing the photo deletes the old one and every render made from it.
  await storage.removePrefix(mediaPaths.participantPrefix(event.id, participant.userId));
  await repo.deleteRendersForUser(event.id, participant.userId);
  const hash = createHash('sha256').update(normalized.bytes).digest('hex');
  const path = mediaPaths.photo(event.id, participant.userId, hash);
  await storage.put(path, normalized.bytes, 'image/jpeg');

  const updated: ParticipantRecord = { ...participant, photoPath: path, photoHash: hash, photoQuality: quality, pose };
  await repo.upsertParticipant(updated);
  const look = await repo.getLook(event.id, participant.userId);
  if (look?.renderRequested) await repo.upsertLook({ ...look, renderRequested: false });

  const [photoUrl] = await signAll(storage, [path]);
  return c.json(participantDto(updated, photoUrl ?? null));
});

events.delete('/events/:eventId/me/photo', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const { repo, storage } = c.var.services;
  await storage.removePrefix(mediaPaths.participantPrefix(event.id, participant.userId));
  await repo.deleteRendersForUser(event.id, participant.userId);
  const updated = { ...participant, photoPath: null, photoHash: null, photoQuality: null };
  await repo.upsertParticipant(updated);
  return c.json(participantDto(updated, null));
});

/** Leave the event: deletes the participant's photo, look and renders. */
events.delete('/events/:eventId/me', requireUser, async (c) => {
  const { event } = await loadParticipantEvent(c, c.req.param('eventId'));
  await removeParticipant(c.var.services, event.id, c.var.userId);
  return c.body(null, 204);
});

events.delete('/events/:eventId/participants/:userId', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const userId = c.req.param('userId');
  if (!(await c.var.services.repo.getParticipant(event.id, userId))) {
    throw new HttpError(404, 'participant_not_found', 'That person is not in this event.');
  }
  await removeParticipant(c.var.services, event.id, userId);
  return c.body(null, 204);
});

async function removeParticipant(services: Services, eventId: string, userId: string) {
  const { repo, storage } = services;
  const participant = await repo.getParticipant(eventId, userId);
  if (participant?.pairWith) {
    const partner = await repo.getParticipant(eventId, participant.pairWith);
    if (partner?.pairWith === userId) await repo.upsertParticipant({ ...partner, pairWith: null });
  }
  await storage.removePrefix(mediaPaths.participantPrefix(eventId, userId));
  await repo.deleteParticipant(eventId, userId);
}
