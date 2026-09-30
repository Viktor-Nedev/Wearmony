import type {
  EventRecord,
  ItemRecord,
  LookRecord,
  ParticipantRecord,
  RenderRecord,
  VendorLinkRecord,
} from '../domain/types.js';
import type { Repository } from './repository.js';

/**
 * In-memory repository for local development, tests and the no-account demo.
 * Data lives as long as the process; objects are copied so callers cannot
 * mutate stored state by accident.
 */
export function createMemoryRepository(): Repository {
  const events = new Map<string, EventRecord>();
  const participants = new Map<string, ParticipantRecord>();
  const items = new Map<string, ItemRecord>();
  const looks = new Map<string, LookRecord>();
  const renders = new Map<string, RenderRecord>();
  const vendorLinks = new Map<string, VendorLinkRecord>();
  const providerFiles = new Map<string, { fileId: string; uploadedAt: string }>();

  const key = (...parts: string[]) => parts.join('/');
  const copy = <T>(value: T): T => structuredClone(value);
  const inEvent = <T extends { eventId: string }>(map: Map<string, T>, eventId: string) =>
    [...map.values()].filter((value) => value.eventId === eventId).map(copy);
  const removeWhere = <T>(map: Map<string, T>, predicate: (value: T) => boolean) => {
    for (const [k, v] of map) if (predicate(v)) map.delete(k);
  };

  return {
    async createEvent(event) {
      events.set(event.id, copy(event));
    },
    async getEvent(id) {
      const event = events.get(id);
      return event ? copy(event) : null;
    },
    async getEventByCode(joinCode) {
      const event = [...events.values()].find((e) => e.joinCode === joinCode);
      return event ? copy(event) : null;
    },
    async listEventsForUser(userId) {
      const joined = new Set([...participants.values()].filter((p) => p.userId === userId).map((p) => p.eventId));
      return [...events.values()]
        .filter((e) => e.organizerId === userId || joined.has(e.id))
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
        .map(copy);
    },
    async updateEvent(id, patch) {
      const event = events.get(id);
      if (event) events.set(id, { ...event, ...patch });
    },
    async deleteEvent(id) {
      events.delete(id);
      for (const map of [participants, items, looks, renders, vendorLinks] as Map<string, { eventId: string }>[]) {
        removeWhere(map, (value) => value.eventId === id);
      }
    },

    async upsertParticipant(participant) {
      participants.set(key(participant.eventId, participant.userId), copy(participant));
    },
    async getParticipant(eventId, userId) {
      const participant = participants.get(key(eventId, userId));
      return participant ? copy(participant) : null;
    },
    async listParticipants(eventId) {
      return inEvent(participants, eventId).sort((a, b) => a.joinedAt.localeCompare(b.joinedAt));
    },
    async deleteParticipant(eventId, userId) {
      participants.delete(key(eventId, userId));
      looks.delete(key(eventId, userId));
      removeWhere(renders, (r) => r.eventId === eventId && r.userId === userId);
      removeWhere(vendorLinks, (l) => l.eventId === eventId && l.userId === userId);
    },

    async upsertItem(item) {
      items.set(key(item.eventId, item.id), copy(item));
    },
    async getItem(eventId, itemId) {
      const item = items.get(key(eventId, itemId));
      return item ? copy(item) : null;
    },
    async listItems(eventId) {
      return inEvent(items, eventId).sort((a, b) => a.createdAt.localeCompare(b.createdAt));
    },
    async deleteItem(eventId, itemId) {
      items.delete(key(eventId, itemId));
      for (const [k, look] of looks) {
        if (look.eventId !== eventId) continue;
        looks.set(k, {
          ...look,
          garmentId: look.garmentId === itemId ? null : look.garmentId,
          makeupId: look.makeupId === itemId ? null : look.makeupId,
          hairId: look.hairId === itemId ? null : look.hairId,
        });
      }
    },

    async upsertLook(look) {
      looks.set(key(look.eventId, look.userId), copy(look));
    },
    async getLook(eventId, userId) {
      const look = looks.get(key(eventId, userId));
      return look ? copy(look) : null;
    },
    async listLooks(eventId) {
      return inEvent(looks, eventId);
    },

    async insertRenderIfAbsent(render) {
      const k = key(render.eventId, render.hash);
      if (renders.has(k)) return false;
      renders.set(k, copy(render));
      return true;
    },
    async upsertRender(render) {
      renders.set(key(render.eventId, render.hash), copy(render));
    },
    async deleteRender(eventId, hash) {
      renders.delete(key(eventId, hash));
    },
    async deleteRendersForUser(eventId, userId) {
      removeWhere(renders, (r) => r.eventId === eventId && r.userId === userId);
    },
    async getRender(eventId, hash) {
      const render = renders.get(key(eventId, hash));
      return render ? copy(render) : null;
    },
    async listRenders(eventId) {
      return inEvent(renders, eventId);
    },

    async createVendorLink(link) {
      vendorLinks.set(link.tokenHash, copy(link));
    },
    async getVendorLink(tokenHash) {
      const link = vendorLinks.get(tokenHash);
      return link ? copy(link) : null;
    },
    async listVendorLinks(eventId) {
      return inEvent(vendorLinks, eventId);
    },
    async deleteVendorLink(tokenHash) {
      vendorLinks.delete(tokenHash);
    },

    async getProviderFile(imageHash) {
      const file = providerFiles.get(imageHash);
      return file ? copy(file) : null;
    },
    async putProviderFile(imageHash, fileId) {
      providerFiles.set(imageHash, { fileId, uploadedAt: new Date().toISOString() });
    },
  };
}
