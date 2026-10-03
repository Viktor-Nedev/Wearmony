import { describe, expect, it } from 'vitest';
import { hexToLab } from './color.js';
import { computeHarmony, type HarmonyPersonInput } from './engine.js';
import { pickTarget, suggestFixes, type SuggestionItem, type SuggestionLook } from './suggest.js';

const colors = (hex: string) => [{ hex, lab: [...hexToLab(hex)] as [number, number, number], share: 0.9 }];

const garment = (id: string, hex: string, price = 50): SuggestionItem => ({
  id,
  type: 'garment',
  name: id,
  price,
  dominantColors: colors(hex),
  colorHex: null,
});
const lips = (id: string, hex: string, price = 15): SuggestionItem => ({
  id,
  type: 'makeup',
  name: id,
  price,
  dominantColors: null,
  colorHex: hex,
});

const ITEMS = [
  garment('blush dress', '#E8A0B4', 180),
  garment('rose tie', '#E39AB6', 35),
  garment('blush tie', '#E8A0B4', 35),
  garment('navy suit', '#1F2A44', 260),
  garment('emerald gown', '#1E7F5C', 210),
];

function person(id: string, outfit: string | null, extra: Partial<HarmonyPersonInput> = {}): HarmonyPersonInput {
  const item = ITEMS.find((i) => i.id === outfit);
  return { id, name: id, partnerId: null, outfit: item?.dominantColors ?? null, lips: null, hair: null, ...extra };
}

function looks(entries: Record<string, Partial<SuggestionLook>>): Map<string, SuggestionLook> {
  return new Map(
    Object.entries(entries).map(([id, look]) => [
      id,
      { garmentId: null, makeupId: null, hairId: null, locked: false, ...look },
    ]),
  );
}

describe('suggestFixes', () => {
  const people = [
    person('Maria', 'blush dress', { partnerId: 'Ivan' }),
    person('Ivan', 'rose tie', { partnerId: 'Maria' }),
    person('Elena', 'emerald gown'),
  ];
  const current = looks({
    Maria: { garmentId: 'blush dress' },
    Ivan: { garmentId: 'rose tie' },
    Elena: { garmentId: 'emerald gown' },
  });
  const target = pickTarget(computeHarmony(people).findings)!;

  it('starts from the near-miss between the partners', () => {
    expect(target.relation).toBe('near_miss');
    expect(target.names).toEqual(['Maria', 'Ivan']);
  });

  it('only suggests swaps that remove the near-miss, best group score first', () => {
    const suggestions = suggestFixes({ people, looks: current, items: ITEMS, perPersonCap: null, target });
    expect(suggestions.length).toBeGreaterThan(0);
    for (const s of suggestions) expect(s.relationAfter).not.toBe('near_miss');
    const scores = suggestions.map((s) => s.groupScoreAfter ?? 0);
    expect([...scores].sort((a, b) => b - a)).toEqual(scores);
    expect(suggestions[0]!.groupScoreAfter).toBeGreaterThan(suggestions[0]!.groupScoreBefore!);
  });

  it('suggests the exact match for the tie, at no extra cost', () => {
    const suggestions = suggestFixes({ people, looks: current, items: ITEMS, perPersonCap: null, target });
    const tie = suggestions.find((s) => s.userId === 'Ivan' && s.itemId === 'blush tie');
    expect(tie).toMatchObject({
      relationAfter: 'matched',
      priceDelta: 0,
      otherUserId: 'Maria',
      otherName: 'Maria',
      warningsAfter: 0,
    });
  });

  it('gives both people in the pair options', () => {
    const suggestions = suggestFixes({ people, looks: current, items: ITEMS, perPersonCap: null, target, limit: 4 });
    expect(new Set(suggestions.map((s) => s.userId))).toEqual(new Set(['Maria', 'Ivan']));
  });

  it('never asks someone with a locked look to change', () => {
    const locked = looks({
      Maria: { garmentId: 'blush dress' },
      Ivan: { garmentId: 'rose tie', locked: true },
      Elena: { garmentId: 'emerald gown' },
    });
    const suggestions = suggestFixes({ people, looks: locked, items: ITEMS, perPersonCap: null, target });
    expect(suggestions.length).toBeGreaterThan(0);
    expect(suggestions.every((s) => s.userId === 'Maria')).toBe(true);
  });

  it('ranks swaps over the per-person budget last and says so', () => {
    const suggestions = suggestFixes({ people, looks: current, items: ITEMS, perPersonCap: 200, target, limit: 10 });
    // Each look here is a single garment, so the new total is the new item's price.
    for (const s of suggestions) expect(s.withinBudget).toBe(s.price <= 200);
    const firstOver = suggestions.findIndex((s) => !s.withinBudget);
    expect(firstOver).toBeGreaterThan(0);
    expect(suggestions.slice(firstOver).every((s) => !s.withinBudget)).toBe(true);
  });

  it('fixes a lip color that nearly matches the outfit by changing only the lip color', () => {
    const solo = [person('Maria', 'blush dress', { lips: '#E39AB6' })];
    const own = pickTarget(computeHarmony(solo).findings, 'Maria')!;
    expect(own.scope).toBe('self');
    const suggestions = suggestFixes({
      people: solo,
      looks: looks({ Maria: { garmentId: 'blush dress', makeupId: 'rose gloss' } }),
      items: [...ITEMS, lips('rose gloss', '#E39AB6'), lips('berry', '#9E2A4B'), lips('blush gloss', '#E8A0B4')],
      perPersonCap: null,
      target: own,
    });
    expect(suggestions.map((s) => s.itemType)).toEqual(suggestions.map(() => 'makeup'));
    expect(suggestions.map((s) => s.itemId)).toEqual(expect.arrayContaining(['berry', 'blush gloss']));
    expect(suggestions.every((s) => s.otherName === null)).toBe(true);
  });

  it('has nothing to suggest when the target is not a near-miss', () => {
    const calm = [person('Maria', 'blush dress'), person('Elena', 'emerald gown')];
    const finding = computeHarmony(calm).findings[0]!;
    expect(suggestFixes({ people: calm, looks: looks({}), items: ITEMS, perPersonCap: null, target: finding })).toEqual(
      [],
    );
  });
});

describe('suggestFixes with categories', () => {
  it('prefers a swap of the same kind when the result is as good', () => {
    const items = [
      { ...garment('blush dress', '#E8A0B4', 180), category: 'full_body' },
      { ...garment('rose tie', '#E39AB6', 35), category: 'upper_body' },
      { ...garment('sage dress', '#9CB59A', 180), category: 'full_body' },
      { ...garment('sage tie', '#9CB59A', 180), category: 'upper_body' },
    ];
    const people = [
      { ...person('Maria', null), outfit: items[0]!.dominantColors },
      { ...person('Ivan', null), outfit: items[1]!.dominantColors },
    ];
    const target = pickTarget(computeHarmony(people).findings)!;
    const suggestions = suggestFixes({
      people,
      looks: looks({ Maria: { garmentId: 'blush dress' }, Ivan: { garmentId: 'rose tie', locked: true } }),
      items,
      perPersonCap: null,
      target,
    });
    // Both sage items give the same contrast; the dress replaces a dress, so it comes first.
    const ids = suggestions.map((s) => s.itemId);
    expect(ids).toContain('sage dress');
    if (ids.includes('sage tie')) expect(ids.indexOf('sage dress')).toBeLessThan(ids.indexOf('sage tie'));
  });
});

describe('pickTarget', () => {
  it('finds the weakest near-miss for one person', () => {
    const people = [
      person('Maria', 'blush dress'),
      person('Ivan', 'rose tie'),
      person('Elena', 'emerald gown'),
    ];
    const findings = computeHarmony(people).findings;
    expect(pickTarget(findings, 'Elena')).toBeNull();
    expect(pickTarget(findings, 'Ivan')?.names).toEqual(['Maria', 'Ivan']);
  });
});
