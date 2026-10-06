// How colors look with a color vision deficiency, and which outfits would look
// alike to such a viewer although they are clearly different for typical vision.
// Simulation: G. M. Machado, M. M. Oliveira, L. A. F. Fernandes, "A Physiologically-based
// Model for Simulation of Color Vision Deficiency" (2009), severity 1.0 (dichromacy),
// applied in linear sRGB. It is an approximation: real color vision varies from person to person.

import { ciede2000, fromLinear, hexToLab, hexToRgb, rgbToHex, toLinear } from './color.js';
import { HARMONY_CONFIG, type HarmonyConfig } from './config.js';
import type { HarmonyPersonInput } from './engine.js';

export type VisionMode = 'protan' | 'deutan' | 'tritan';
export const VISION_MODES: VisionMode[] = ['protan', 'deutan', 'tritan'];

type Matrix = readonly [readonly [number, number, number], readonly [number, number, number], readonly [number, number, number]];

const MATRICES: Record<VisionMode, Matrix> = {
  protan: [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  deutan: [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.01182, 0.04294, 0.968881],
  ],
  tritan: [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.3039],
  ],
};

/** The color as it would look to a viewer with the given dichromacy. */
export function simulateHex(hex: string, mode: VisionMode): string {
  const linear = hexToRgb(hex).map(toLinear);
  const m = MATRICES[mode];
  const out = m.map((row) => row[0] * linear[0]! + row[1] * linear[1]! + row[2] * linear[2]!);
  return rgbToHex([fromLinear(out[0]!), fromLinear(out[1]!), fromLinear(out[2]!)]);
}

export interface VisionPerson {
  id: string;
  name: string;
  outfit: string | null;
  lips: string | null;
  hair: string | null;
}

export interface LookAlikePair {
  people: [string, string];
  names: [string, string];
  partners: boolean;
  /** ΔE00 for typical vision. */
  typicalDeltaE: number;
  /** ΔE00 in the simulated view. */
  deltaE: number;
}

export interface VisionView {
  mode: VisionMode;
  people: VisionPerson[];
  /** Outfits that look alike in this view only, closest first. */
  lookAlike: LookAlikePair[];
}

const round1 = (n: number) => Math.round(n * 10) / 10;

export function visionReport(people: HarmonyPersonInput[], config: HarmonyConfig = HARMONY_CONFIG): VisionView[] {
  const outfitHex = (p: HarmonyPersonInput) => p.outfit?.[0]?.hex ?? null;
  return VISION_MODES.map((mode) => {
    const sim = (hex: string | null) => (hex ? simulateHex(hex, mode) : null);
    const view = people.map((p) => ({ id: p.id, name: p.name, outfit: sim(outfitHex(p)), lips: sim(p.lips), hair: sim(p.hair) }));

    const lookAlike: LookAlikePair[] = [];
    for (let i = 0; i < people.length; i++) {
      for (let j = i + 1; j < people.length; j++) {
        const a = outfitHex(people[i]!);
        const b = outfitHex(people[j]!);
        if (!a || !b) continue;
        const typical = ciede2000(hexToLab(a), hexToLab(b));
        if (typical <= config.nearMissMax) continue; // already reported by the harmony check
        const simulated = ciede2000(hexToLab(view[i]!.outfit!), hexToLab(view[j]!.outfit!));
        if (simulated > config.vision.lookAlikeMax) continue;
        lookAlike.push({
          people: [people[i]!.id, people[j]!.id],
          names: [people[i]!.name, people[j]!.name],
          partners: people[i]!.partnerId === people[j]!.id || people[j]!.partnerId === people[i]!.id,
          typicalDeltaE: round1(typical),
          deltaE: round1(simulated),
        });
      }
    }
    lookAlike.sort((x, y) => x.deltaE - y.deltaE);
    return { mode, people: view, lookAlike };
  });
}
