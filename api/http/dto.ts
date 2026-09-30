import type { EventRecord, ItemRecord, LookRecord, ParticipantRecord } from '../domain/types.js';
import type { LookRenderState } from '../render/pipeline.js';
import type { MediaStorage } from '../storage/storage.js';

/** Signed URLs live for an hour; the app refreshes data long before that. */
export const URL_TTL_SECONDS = 3600;

/** Signs many paths in one call; nulls stay null. */
export async function signAll(storage: MediaStorage, paths: (string | null | undefined)[]): Promise<(string | null)[]> {
  const present = paths.filter((p): p is string => Boolean(p));
  if (present.length === 0) return paths.map(() => null);
  const urls = await storage.signedUrls(present, URL_TTL_SECONDS);
  const byPath = new Map(present.map((p, i) => [p, urls[i]!]));
  return paths.map((p) => (p ? (byPath.get(p) ?? null) : null));
}

export function eventDto(event: EventRecord, access: { isOrganizer: boolean; isParticipant: boolean }) {
  return {
    id: event.id,
    name: event.name,
    template: event.template,
    joinCode: event.joinCode,
    budgetPerPerson: event.budgetPerPerson,
    budgetTotal: event.budgetTotal,
    currency: event.currency,
    demo: event.demo,
    createdAt: event.createdAt,
    isOrganizer: access.isOrganizer,
    isParticipant: access.isParticipant,
  };
}

export function participantDto(p: ParticipantRecord, photoUrl: string | null) {
  return {
    userId: p.userId,
    displayName: p.displayName,
    pairWith: p.pairWith,
    pose: p.pose,
    consentAt: p.consentAt,
    hasPhoto: Boolean(p.photoPath),
    photoUrl,
    photoQuality: p.photoQuality,
    joinedAt: p.joinedAt,
  };
}

export function itemDto(item: ItemRecord, imageUrl: string | null) {
  return {
    id: item.id,
    type: item.type,
    name: item.name,
    price: item.price,
    category: item.category,
    colorHex: item.colorHex ?? item.dominantColors?.[0]?.hex ?? null,
    colors: (item.dominantColors ?? []).map((c) => ({ hex: c.hex, share: c.share })),
    imageUrl,
    vendorName: item.vendorName,
    hasImage: Boolean(item.imagePath),
  };
}

export function lookTotal(look: LookRecord | null, items: Map<string, ItemRecord>): number {
  if (!look) return 0;
  const total = [look.garmentId, look.makeupId, look.hairId]
    .map((id) => (id ? (items.get(id)?.price ?? 0) : 0))
    .reduce((sum, price) => sum + price, 0);
  return Math.round(total * 100) / 100;
}

export function renderDto(state: LookRenderState, resultUrl: string | null) {
  return {
    status: state.status,
    steps: state.steps,
    current: state.current,
    progress: Math.round(state.progress * 100) / 100,
    resultUrl,
    failure: state.failure,
    mock: state.mock,
    checks: state.checks,
    units: state.units,
  };
}

export const iso = (ms: number) => new Date(ms).toISOString();
