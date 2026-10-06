import { Hono } from 'hono';
import { z } from 'zod';
import type { ItemRecord, LookRecord, ParticipantRecord, PollRecord, PollVoteRecord } from '../../domain/types.js';
import { scorePollOptions } from '../../harmony/poll.js';
import type { Services } from '../../services.js';
import { HttpError, loadParticipantEvent, parseJson, requireUser, type AppEnv } from '../context.js';
import { iso, signAll } from '../dto.js';
import { harmonyInputs } from './board.js';
import { emptyLook, itemMap } from './looks.js';

/**
 * "Ask the group": a participant who cannot decide offers two or three garments,
 * the others vote, and every option shows what it would do to the group's harmony.
 * The votes are advice; only the participant changes their own look.
 */
export const polls = new Hono<AppEnv>();

export const POLL_MIN_OPTIONS = 2;
export const POLL_MAX_OPTIONS = 3;

const StartPoll = z.object({
  itemIds: z
    .array(z.string().uuid())
    .min(POLL_MIN_OPTIONS)
    .max(POLL_MAX_OPTIONS)
    .refine((ids) => new Set(ids).size === ids.length, 'Each option must be a different garment.'),
});
const Vote = z.object({ itemId: z.string().uuid() });

export async function buildPolls(
  services: Services,
  data: {
    participants: ParticipantRecord[];
    looks: Map<string, LookRecord>;
    items: Map<string, ItemRecord>;
    polls: PollRecord[];
    votes: PollVoteRecord[];
  },
  viewerId: string,
) {
  const { participants, looks, items } = data;
  const names = new Map(participants.map((p) => [p.userId, p.displayName]));
  const viewerIsParticipant = names.has(viewerId);
  const people = harmonyInputs(participants, looks, items);
  const before = new Map(people.map((p) => [p.id, p]));

  const open = data.polls
    .filter((poll) => names.has(poll.userId))
    .map((poll) => ({
      poll,
      // Items deleted from the catalogue drop out of the poll.
      options: poll.itemIds.map((id) => items.get(id)).filter((i): i is ItemRecord => i?.type === 'garment'),
    }))
    .filter(({ options }) => options.length > 0);

  const urls = await signAll(
    services.storage,
    open.flatMap(({ options }) => options.map((o) => o.imagePath)),
  );
  let urlIndex = 0;

  return open.map(({ poll, options }) => {
    const votes = data.votes.filter((v) => v.ownerId === poll.userId && options.some((o) => o.id === v.itemId));
    const tally = (itemId: string) => votes.filter((v) => v.itemId === itemId);
    const top = Math.max(0, ...options.map((o) => tally(o.id).length));
    const harmony = before.has(poll.userId)
      ? scorePollOptions(people, poll.userId, options)
      : options.map(() => null);
    return {
      ownerId: poll.userId,
      ownerName: names.get(poll.userId)!,
      isMine: poll.userId === viewerId,
      canVote: viewerIsParticipant && poll.userId !== viewerId,
      myVote: votes.find((v) => v.voterId === viewerId)?.itemId ?? null,
      currentGarmentId: looks.get(poll.userId)?.garmentId ?? null,
      totalVotes: votes.length,
      createdAt: poll.createdAt,
      options: options.map((item, i) => ({
        itemId: item.id,
        name: item.name,
        price: item.price,
        colorHex: item.dominantColors?.[0]?.hex ?? null,
        imageUrl: urls[urlIndex++] ?? null,
        votes: tally(item.id).length,
        voters: tally(item.id).map((v) => names.get(v.voterId) ?? ''),
        leading: top > 0 && tally(item.id).length === top,
        harmony: harmony[i]
          ? {
              groupScore: harmony[i]!.groupScore,
              warnings: harmony[i]!.warnings,
              ownWarnings: harmony[i]!.ownWarnings,
              partnerRelation: harmony[i]!.partnerRelation,
            }
          : null,
      })),
    };
  });
}

polls.put('/events/:eventId/poll', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const { itemIds } = await parseJson(c, StartPoll);
  const { repo, now } = c.var.services;
  const look = await repo.getLook(event.id, participant.userId);
  if (look?.locked) throw new HttpError(423, 'look_locked', 'Unlock your look before asking the group.');
  const items = await itemMap(c.var.services, event.id);
  if (itemIds.some((id) => items.get(id)?.type !== 'garment')) {
    throw new HttpError(400, 'invalid_item', 'Pick garments from this event’s catalogue.');
  }
  await repo.replacePoll({ eventId: event.id, userId: participant.userId, itemIds, createdAt: iso(now()) });
  return c.body(null, 204);
});

polls.delete('/events/:eventId/poll', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  await c.var.services.repo.deletePoll(event.id, participant.userId);
  return c.body(null, 204);
});

/** The owner wears the option they choose (the vote never changes a look by itself) and the poll closes. */
polls.post('/events/:eventId/poll/choose', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const { itemId } = await parseJson(c, Vote);
  const { repo, now } = c.var.services;
  const poll = await repo.getPoll(event.id, participant.userId);
  if (!poll) throw new HttpError(404, 'poll_not_found', 'You have no open question to the group.');
  if (!poll.itemIds.includes(itemId)) throw new HttpError(400, 'invalid_option', 'That garment is not one of the options.');
  if (!(await repo.getItem(event.id, itemId))) throw new HttpError(404, 'item_not_found', 'That garment was removed from the catalogue.');
  const look = (await repo.getLook(event.id, participant.userId)) ?? emptyLook(event.id, participant.userId, now());
  if (look.locked) throw new HttpError(423, 'look_locked', 'Unlock your look before changing it.');
  await repo.upsertLook({ ...look, garmentId: itemId, renderRequested: false, updatedAt: iso(now()) });
  await repo.deletePoll(event.id, participant.userId);
  return c.body(null, 204);
});

polls.put('/events/:eventId/polls/:ownerId/vote', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  const ownerId = c.req.param('ownerId');
  const { itemId } = await parseJson(c, Vote);
  const { repo, now } = c.var.services;
  if (ownerId === participant.userId) throw new HttpError(403, 'own_poll', 'The group votes on your question, not you.');
  const poll = await repo.getPoll(event.id, ownerId);
  if (!poll) throw new HttpError(404, 'poll_not_found', 'This question was closed.');
  if (!poll.itemIds.includes(itemId)) throw new HttpError(400, 'invalid_option', 'That garment is not one of the options.');
  await repo.castVote({ eventId: event.id, ownerId, voterId: participant.userId, itemId, votedAt: iso(now()) });
  return c.body(null, 204);
});

polls.delete('/events/:eventId/polls/:ownerId/vote', requireUser, async (c) => {
  const { event, participant } = await loadParticipantEvent(c, c.req.param('eventId'));
  await c.var.services.repo.deleteVote(event.id, c.req.param('ownerId'), participant.userId);
  return c.body(null, 204);
});
