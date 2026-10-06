import type { ItemRecord, LookRecord, ParticipantRecord, PollRecord, PollVoteRecord, RenderRecord } from './types.js';

// Recent activity in an event, derived from timestamps the records already keep:
// who joined, who chose or locked a look, who tried their look on, who asked
// the group about an outfit and who voted.

export type ActivityKind = 'joined' | 'look' | 'locked' | 'previewed' | 'asked' | 'voted';

export interface ActivityEntry {
  kind: ActivityKind;
  userId: string;
  name: string;
  /** For a chosen look: the garment's name. For a vote: whose question it was. */
  item: string | null;
  at: string;
}

export function recentActivity(
  participants: ParticipantRecord[],
  looks: Map<string, LookRecord>,
  items: Map<string, ItemRecord>,
  renders: RenderRecord[],
  limit = 8,
  group: { polls?: PollRecord[]; votes?: PollVoteRecord[] } = {},
): ActivityEntry[] {
  const names = new Map(participants.map((p) => [p.userId, p.displayName]));
  const entries: ActivityEntry[] = participants.map((p) => ({
    kind: 'joined',
    userId: p.userId,
    name: p.displayName,
    item: null,
    at: p.joinedAt,
  }));

  for (const look of looks.values()) {
    const name = names.get(look.userId);
    if (!name) continue;
    if (look.locked) {
      entries.push({ kind: 'locked', userId: look.userId, name, item: null, at: look.updatedAt });
      continue;
    }
    const garment = look.garmentId ? items.get(look.garmentId) : undefined;
    if (garment) entries.push({ kind: 'look', userId: look.userId, name, item: garment.name, at: look.updatedAt });
  }

  // One entry per person for their latest finished preview.
  const latest = new Map<string, number>();
  for (const render of renders) {
    if (render.status !== 'success' || !names.has(render.userId)) continue;
    const at = Date.parse(render.updatedAt);
    if (at > (latest.get(render.userId) ?? -Infinity)) latest.set(render.userId, at);
  }
  for (const [userId, at] of latest) {
    entries.push({ kind: 'previewed', userId, name: names.get(userId)!, item: null, at: new Date(at).toISOString() });
  }

  for (const poll of group.polls ?? []) {
    const name = names.get(poll.userId);
    if (name) entries.push({ kind: 'asked', userId: poll.userId, name, item: null, at: poll.createdAt });
  }
  for (const vote of group.votes ?? []) {
    const name = names.get(vote.voterId);
    const owner = names.get(vote.ownerId);
    if (name && owner) entries.push({ kind: 'voted', userId: vote.voterId, name, item: owner, at: vote.votedAt });
  }

  // Timestamps from the database and from the app can differ in format, so compare instants.
  return entries
    .map((entry) => ({ entry, time: Date.parse(entry.at) }))
    .filter(({ time }) => Number.isFinite(time))
    .sort((a, b) => b.time - a.time)
    .slice(0, limit)
    .map(({ entry, time }) => ({ ...entry, at: new Date(time).toISOString() }));
}
