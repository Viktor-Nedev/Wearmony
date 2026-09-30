import type { Context } from 'hono';
import { createMiddleware } from 'hono/factory';
import type { z } from 'zod';
import type { EventRecord, ParticipantRecord } from '../domain/types.js';
import type { Services } from '../services.js';

export interface AppEnv {
  Variables: {
    services: Services;
    userId: string;
  };
}

export type AppContext = Context<AppEnv>;

/** An error with an HTTP status and a stable code the client can translate. */
export class HttpError extends Error {
  constructor(
    readonly status: 400 | 401 | 403 | 404 | 409 | 410 | 413 | 415 | 422 | 423 | 503,
    readonly code: string,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export const requireUser = createMiddleware<AppEnv>(async (c, next) => {
  const header = c.req.header('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
  const userId = token ? await c.var.services.auth.verify(token) : null;
  if (!userId) throw new HttpError(401, 'unauthorized', 'Sign in to continue.');
  c.set('userId', userId);
  await next();
});

export async function parseJson<T extends z.ZodType>(c: AppContext, schema: T): Promise<z.infer<T>> {
  const body = await c.req.json().catch(() => null);
  const parsed = schema.safeParse(body);
  if (!parsed.success) throw new HttpError(400, 'invalid_request', 'The request is not valid.', parsed.error.issues);
  return parsed.data;
}

export interface EventAccess {
  event: EventRecord;
  participant: ParticipantRecord | null;
  isOrganizer: boolean;
}

/** Loads an event the caller belongs to. Outsiders get 404, so event ids reveal nothing. */
export async function loadEvent(c: AppContext, eventId: string): Promise<EventAccess> {
  const { repo } = c.var.services;
  const event = await repo.getEvent(eventId);
  if (!event) throw new HttpError(404, 'event_not_found', 'This event does not exist or was deleted.');
  const participant = await repo.getParticipant(eventId, c.var.userId);
  const isOrganizer = event.organizerId === c.var.userId;
  if (!participant && !isOrganizer) throw new HttpError(404, 'event_not_found', 'This event does not exist or was deleted.');
  return { event, participant, isOrganizer };
}

export async function loadOrganizerEvent(c: AppContext, eventId: string): Promise<EventAccess> {
  const access = await loadEvent(c, eventId);
  if (!access.isOrganizer) throw new HttpError(403, 'organizer_only', 'Only the organizer can do this.');
  return access;
}

export async function loadParticipantEvent(c: AppContext, eventId: string): Promise<EventAccess & { participant: ParticipantRecord }> {
  const access = await loadEvent(c, eventId);
  if (!access.participant) throw new HttpError(403, 'not_participant', 'Join the event as a participant first.');
  return { ...access, participant: access.participant };
}

/** Reads a raw image upload, enforcing type and size. */
export async function readImageBody(c: AppContext, maxBytes = 8 * 1024 * 1024): Promise<Buffer> {
  const type = (c.req.header('content-type') ?? '').split(';')[0]!.trim().toLowerCase();
  if (!['image/jpeg', 'image/jpg', 'image/png'].includes(type)) {
    throw new HttpError(415, 'unsupported_image', 'Upload a JPG or PNG image.');
  }
  const bytes = Buffer.from(await c.req.arrayBuffer());
  if (bytes.length === 0) throw new HttpError(400, 'empty_upload', 'The upload was empty.');
  if (bytes.length > maxBytes) throw new HttpError(413, 'image_too_large', 'The image is too large (limit 8 MB).');
  return bytes;
}
