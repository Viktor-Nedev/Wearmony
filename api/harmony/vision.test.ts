import { describe, expect, it } from 'vitest';
import { ciede2000, hexToLab } from './color.js';
import type { HarmonyPersonInput } from './engine.js';
import { simulateHex, visionReport } from './vision.js';

const colors = (hex: string) => [{ hex, lab: [...hexToLab(hex)] as [number, number, number], share: 0.9 }];
const person = (id: string, outfit: string | null, partnerId: string | null = null): HarmonyPersonInput => ({
  id,
  name: id,
  partnerId,
  outfit: outfit ? colors(outfit) : null,
  lips: null,
  hair: null,
});
const dE = (a: string, b: string) => ciede2000(hexToLab(a), hexToLab(b));

describe('simulateHex', () => {
  it('keeps black, white and grays unchanged', () => {
    for (const mode of ['protan', 'deutan', 'tritan'] as const) {
      expect(simulateHex('#000000', mode)).toBe('#000000');
      expect(simulateHex('#FFFFFF', mode)).toBe('#FFFFFF');
      expect(dE(simulateHex('#808080', mode), '#808080')).toBeLessThan(1);
    }
  });

  it('brings red and green close together for red-green deficiencies only', () => {
    const red = '#C0392B';
    const green = '#6B8E23';
    expect(dE(red, green)).toBeGreaterThan(30);
    expect(dE(simulateHex(red, 'deutan'), simulateHex(green, 'deutan'))).toBeLessThan(dE(red, green) / 2);
    expect(dE(simulateHex(red, 'tritan'), simulateHex(green, 'tritan'))).toBeGreaterThan(20);
  });

  it('brings blue and green close together for tritanopia', () => {
    const blue = '#2E86C1';
    const teal = '#17A589';
    expect(dE(simulateHex(blue, 'tritan'), simulateHex(teal, 'tritan'))).toBeLessThan(dE(blue, teal));
  });
});

describe('visionReport', () => {
  it('lists outfits that look alike only in the simulated view', () => {
    const report = visionReport([
      person('Maria', '#C0392B', 'Ivan'),
      person('Ivan', '#6B8E23', 'Maria'),
      person('Elena', '#1F2A44'),
      person('Georgi', null),
    ]);
    expect(report.map((v) => v.mode)).toEqual(['protan', 'deutan', 'tritan']);
    const deutan = report.find((v) => v.mode === 'deutan')!;
    expect(deutan.people.find((p) => p.id === 'Georgi')!.outfit).toBeNull();
    expect(deutan.lookAlike).toHaveLength(1);
    expect(deutan.lookAlike[0]).toMatchObject({ names: ['Maria', 'Ivan'], partners: true });
    expect(deutan.lookAlike[0]!.typicalDeltaE).toBeGreaterThan(30);
    expect(report.find((v) => v.mode === 'tritan')!.lookAlike).toEqual([]);
  });

  it('leaves near-misses for typical vision to the harmony check', () => {
    const report = visionReport([person('a', '#E8A0B4'), person('b', '#E39AB6')]);
    expect(report.every((v) => v.lookAlike.length === 0)).toBe(true);
  });
});
