import { describe, expect, it } from 'vitest';
import { hexToLab } from './color.js';
import { checkDressCode } from './dresscode.js';
import type { HarmonyPersonInput } from './engine.js';

const person = (id: string, hex: string | null): HarmonyPersonInput => ({
  id,
  name: id,
  partnerId: null,
  outfit: hex ? [{ hex, lab: [...hexToLab(hex)] as [number, number, number], share: 0.9 }] : null,
  lips: null,
  hair: null,
});

describe('checkDressCode', () => {
  const palette = ['#1F2A44', '#E9D8B8'];

  it('places each outfit on, close to or outside the dress code by its nearest color', () => {
    const report = checkDressCode(
      [person('navy', '#1F2A44'), person('dusk', '#3A4A6E'), person('emerald', '#1E7F5C'), person('none', null)],
      palette,
    )!;
    expect(report.people.map((p) => [p.name, p.fit])).toEqual([
      ['navy', 'on'],
      ['dusk', 'close'],
      ['emerald', 'off'],
    ]);
    expect(report.people[0]).toMatchObject({ deltaE: 0, nearest: '#1F2A44', outfit: '#1F2A44' });
    expect(report).toMatchObject({ onCount: 1, total: 3, palette });
  });

  it('has no report without a dress code', () => {
    expect(checkDressCode([person('navy', '#1F2A44')], [])).toBeNull();
  });
});
