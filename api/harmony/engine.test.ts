import { describe, expect, it } from 'vitest';
import { ciede2000, hexToLab } from './color.js';
import { HARMONY_CONFIG } from './config.js';
import { computeHarmony, relate, type HarmonyPersonInput } from './engine.js';

const outfit = (hex: string) => [{ hex, lab: [...hexToLab(hex)] as [number, number, number], share: 0.9 }];

function person(id: string, hex: string | null, extra: Partial<HarmonyPersonInput> = {}): HarmonyPersonInput {
  return { id, name: id, partnerId: null, outfit: hex ? outfit(hex) : null, lips: null, hair: null, ...extra };
}

describe('relate', () => {
  it('treats nearly identical colors as an intentional match', () => {
    expect(relate(hexToLab('#B03A5B'), hexToLab('#B13B5B')).relation).toBe('matched');
  });

  it('warns about colors that are close but not equal', () => {
    const a = hexToLab('#E8A0B4');
    const b = hexToLab('#E39AB6');
    const d = ciede2000(a, b);
    expect(d).toBeGreaterThan(HARMONY_CONFIG.matchMax);
    expect(d).toBeLessThan(HARMONY_CONFIG.nearMissMax);
    expect(relate(a, b).relation).toBe('near_miss');
  });

  it('scores a near-miss worst in the middle of the band', () => {
    const base = hexToLab('#3A6EA5');
    const middle = relate(base, [base[0] + 5, base[1], base[2]]);
    const edge = relate(base, [base[0] + 7.5, base[1], base[2]]);
    expect(middle.relation).toBe('near_miss');
    expect(edge.relation).toBe('near_miss');
    expect(middle.score).toBeLessThan(edge.score);
  });

  it('recognises complementary hues', () => {
    expect(relate(hexToLab('#1F4E9C'), hexToLab('#D4A017')).relation).toBe('complementary');
    expect(relate(hexToLab('#1F4E9C'), hexToLab('#D9822B')).relation).toBe('complementary');
  });

  it('calls other clearly different colors a contrast', () => {
    expect(relate(hexToLab('#1F4E9C'), hexToLab('#2E8B57')).relation).toBe('contrast');
    expect(relate(hexToLab('#FFFFFF'), hexToLab('#B03A5B')).relation).toBe('contrast');
  });

  it('does not flag two very dark colors that differ slightly', () => {
    expect(relate(hexToLab('#141414'), hexToLab('#1C1A24')).relation).toBe('matched');
  });
});

describe('computeHarmony', () => {
  it('reports the weakest pair as the group score and names who is involved', () => {
    const report = computeHarmony([
      person('Maria', '#E8A0B4', { partnerId: 'Ivan' }),
      person('Ivan', '#E39AB6', { partnerId: 'Maria' }),
      person('Elena', '#1F4E9C'),
    ]);
    expect(report.weakest?.relation).toBe('near_miss');
    expect(report.weakest?.names).toEqual(['Maria', 'Ivan']);
    expect(report.weakest?.partners).toBe(true);
    expect(report.groupScore).toBe(report.weakest?.score);
    expect(report.findings).toHaveLength(3);
    expect(report.weakest?.sentence).toMatch(/^Maria's pink and Ivan's pink are close but not the same shade/);
  });

  it('compares hair and lip color with the same person outfit', () => {
    const report = computeHarmony([person('Ana', '#7A1F3D', { hair: '#8C2A48', lips: '#FFFFFF' })]);
    const hair = report.findings.find((f) => f.subjects[0] === 'hair');
    const lips = report.findings.find((f) => f.subjects[0] === 'lips');
    expect(hair?.scope).toBe('self');
    expect(hair?.relation).toBe('near_miss');
    expect(hair?.sentence).toContain("Ana's burgundy hair color is close to, but not the same as, the burgundy outfit");
    expect(lips?.relation).toBe('contrast');
  });

  it('lists people without an outfit and gives no score without comparisons', () => {
    const report = computeHarmony([person('A', null), person('B', '#123456')]);
    expect(report.withoutOutfit).toEqual(['A']);
    expect(report.groupScore).toBeNull();
    expect(report.findings).toEqual([]);
  });

  it('is deterministic', () => {
    const people = [person('A', '#E8A0B4'), person('B', '#E39AB6'), person('C', '#1F4E9C')];
    expect(computeHarmony(people)).toEqual(computeHarmony(people));
  });
});
