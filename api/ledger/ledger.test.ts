import { describe, expect, it } from 'vitest';
import type { RenderRecord } from '../domain/types.js';
import { decideBudget, summarizeUnits } from './ledger.js';

const limits = { perEvent: 10, perParticipant: 4, accountReserve: 2 };

describe('decideBudget', () => {
  it('allows free calls and calls within every cap', () => {
    expect(decideBudget(0, { event: 99, participant: 99 }, 0, limits).allowed).toBe(true);
    expect(decideBudget(2, { event: 6, participant: 2 }, 30, limits).allowed).toBe(true);
  });

  it('stops at the event cap, then the participant cap, then the account reserve', () => {
    expect(decideBudget(2, { event: 9, participant: 0 }, 30, limits)).toMatchObject({ allowed: false, scope: 'event' });
    expect(decideBudget(2, { event: 0, participant: 3 }, 30, limits)).toMatchObject({ allowed: false, scope: 'participant' });
    expect(decideBudget(2, { event: 0, participant: 0 }, 3, limits)).toMatchObject({ allowed: false, scope: 'account' });
  });

  it('ignores the account when the balance is unknown', () => {
    expect(decideBudget(2, { event: 0, participant: 0 }, null, limits).allowed).toBe(true);
  });
});

describe('summarizeUnits', () => {
  it('adds units per event and per participant', () => {
    const renders = [
      { userId: 'a', units: 2 },
      { userId: 'a', units: 1 },
      { userId: 'b', units: 2 },
    ] as RenderRecord[];
    expect(summarizeUnits(renders)).toEqual({ event: 5, byUser: { a: 3, b: 2 } });
  });
});
