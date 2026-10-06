import { describe, expect, it } from 'vitest';
import { hexToLab } from './color.js';
import type { HarmonyPersonInput } from './engine.js';
import { scorePollOptions } from './poll.js';

const colors = (hex: string) => [{ hex, lab: [...hexToLab(hex)] as [number, number, number], share: 0.9 }];

const person = (id: string, outfit: string | null, extra: Partial<HarmonyPersonInput> = {}): HarmonyPersonInput => ({
  id,
  name: id,
  partnerId: null,
  outfit: outfit ? colors(outfit) : null,
  lips: null,
  hair: null,
  ...extra,
});

describe('scorePollOptions', () => {
  const people = [
    person('Maria', '#E8A0B4', { partnerId: 'Ivan' }),
    person('Ivan', null, { partnerId: 'Maria' }),
    person('Elena', '#1E7F5C'),
  ];

  it('scores each option with the owner wearing it', () => {
    const [rose, blush, navy] = scorePollOptions(people, 'Ivan', [
      { id: 'rose tie', dominantColors: colors('#E39AB6') },
      { id: 'blush tie', dominantColors: colors('#E8A0B4') },
      { id: 'navy suit', dominantColors: colors('#1F2A44') },
    ]);
    expect(rose).toMatchObject({ itemId: 'rose tie', ownWarnings: 1, warnings: 1, partnerRelation: 'near_miss' });
    expect(blush).toMatchObject({ ownWarnings: 0, warnings: 0, partnerRelation: 'matched' });
    expect(navy!.ownWarnings).toBe(0);
    expect(navy!.partnerRelation).not.toBe('near_miss');
    expect(rose!.groupScore!).toBeLessThan(blush!.groupScore!);
  });

  it('counts a clash with the owner’s own lip color', () => {
    const withLips = people.map((p) => (p.id === 'Elena' ? { ...p, lips: '#B0304A' } : p));
    const [option] = scorePollOptions(withLips, 'Elena', [{ id: 'red dress', dominantColors: colors('#B83A50') }]);
    expect(option!.ownWarnings).toBe(1);
    expect(option!.partnerRelation).toBeNull();
  });

  it('reports no score instead of guessing when colors are missing', () => {
    const [option] = scorePollOptions(people, 'Ivan', [{ id: 'no image', dominantColors: null }]);
    expect(option).toEqual({ itemId: 'no image', groupScore: null, warnings: 0, ownWarnings: 0, partnerRelation: null });
    expect(scorePollOptions(people, 'nobody', [{ id: 'x', dominantColors: colors('#000000') }])[0]!.groupScore).toBeNull();
  });
});
