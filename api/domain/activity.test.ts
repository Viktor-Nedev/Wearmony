import { describe, expect, it } from 'vitest';
import { recentActivity } from './activity.js';
import type { ItemRecord, LookRecord, ParticipantRecord, RenderRecord } from './types.js';

const person = (userId: string, joinedAt: string): ParticipantRecord => ({
  eventId: 'e',
  userId,
  displayName: userId,
  pairWith: null,
  photoPath: null,
  photoHash: null,
  photoQuality: null,
  pose: null,
  consentAt: null,
  joinedAt,
});

const look = (userId: string, garmentId: string | null, updatedAt: string, locked = false): LookRecord => ({
  eventId: 'e',
  userId,
  garmentId,
  makeupId: null,
  hairId: null,
  locked,
  renderRequested: false,
  updatedAt,
});

const item = { id: 'tie', name: 'Blush tie' } as ItemRecord;

const render = (userId: string, status: RenderRecord['status'], updatedAt: string) =>
  ({ userId, status, updatedAt }) as RenderRecord;

describe('recentActivity', () => {
  it('lists who asked the group and who voted on whose question', () => {
    const people = [person('ana', '2026-10-01T10:00:00Z'), person('boris', '2026-10-01T10:05:00Z')];
    const activity = recentActivity(people, new Map(), new Map(), [], 8, {
      polls: [{ eventId: 'e', userId: 'boris', itemIds: ['a', 'b'], createdAt: '2026-10-01T11:00:00Z' }],
      votes: [
        { eventId: 'e', ownerId: 'boris', voterId: 'ana', itemId: 'a', votedAt: '2026-10-01T12:00:00Z' },
        { eventId: 'e', ownerId: 'gone', voterId: 'ana', itemId: 'a', votedAt: '2026-10-01T12:30:00Z' },
      ],
    });
    expect(activity.slice(0, 2)).toEqual([
      { kind: 'voted', userId: 'ana', name: 'ana', item: 'boris', at: '2026-10-01T12:00:00.000Z' },
      { kind: 'asked', userId: 'boris', name: 'boris', item: null, at: '2026-10-01T11:00:00.000Z' },
    ]);
  });

  const participants = [person('Maria', '2026-10-01T10:00:00Z'), person('Ivan', '2026-10-01T11:00:00Z')];
  const looks = new Map([
    ['Maria', look('Maria', 'tie', '2026-10-02T09:00:00Z', true)],
    ['Ivan', look('Ivan', 'tie', '2026-10-02T12:00:00Z')],
  ]);
  const items = new Map([['tie', item]]);

  it('lists joins, chosen and locked looks and the latest preview, newest first', () => {
    const renders = [
      render('Ivan', 'success', '2026-10-02T10:00:00Z'),
      render('Ivan', 'success', '2026-10-02T11:00:00Z'),
      render('Maria', 'failed', '2026-10-02T13:00:00Z'),
    ];
    const activity = recentActivity(participants, looks, items, renders);
    expect(activity.map((a) => [a.kind, a.name])).toEqual([
      ['look', 'Ivan'],
      ['previewed', 'Ivan'],
      ['locked', 'Maria'],
      ['joined', 'Ivan'],
      ['joined', 'Maria'],
    ]);
    expect(activity[0]).toMatchObject({ item: 'Blush tie', at: '2026-10-02T12:00:00.000Z' });
  });

  it('orders timestamps written in different formats by time', () => {
    const mixed = [person('Maria', '2026-10-01T10:00:00+00:00'), person('Ivan', '2026-10-01T09:30:00.000Z')];
    const activity = recentActivity(mixed, new Map(), items, []);
    expect(activity.map((a) => a.name)).toEqual(['Maria', 'Ivan']);
  });

  it('keeps only the newest entries', () => {
    expect(recentActivity(participants, looks, items, [], 2)).toHaveLength(2);
  });
});
