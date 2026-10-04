import { ciede2000, hexToLab } from './color.js';
import { HARMONY_CONFIG, type HarmonyConfig } from './config.js';
import type { HarmonyPersonInput } from './engine.js';

// Dress code: the organizer picks a few event colors, and each outfit's main
// color is measured against the nearest one with the same CIEDE2000 math as
// the harmony check. It never changes the group score; it is its own report.

export type DressCodeFit = 'on' | 'close' | 'off';

export interface DressCodePerson {
  userId: string;
  name: string;
  fit: DressCodeFit;
  /** ΔE00 to the nearest dress-code color, one decimal. */
  deltaE: number;
  /** That nearest dress-code color. */
  nearest: string;
  /** The outfit's main color. */
  outfit: string;
}

export interface DressCodeReport {
  palette: string[];
  people: DressCodePerson[];
  onCount: number;
  total: number;
}

export function checkDressCode(
  people: HarmonyPersonInput[],
  palette: string[],
  config: HarmonyConfig = HARMONY_CONFIG,
): DressCodeReport | null {
  if (palette.length === 0) return null;
  const colors = palette.map((hex) => ({ hex, lab: hexToLab(hex) }));
  const checked: DressCodePerson[] = [];
  for (const person of people) {
    const main = person.outfit?.[0];
    if (!main) continue;
    let nearest = colors[0]!;
    let distance = Infinity;
    for (const color of colors) {
      const d = ciede2000(main.lab, color.lab);
      if (d < distance) {
        distance = d;
        nearest = color;
      }
    }
    const fit: DressCodeFit =
      distance <= config.dressCode.onMax ? 'on' : distance <= config.dressCode.closeMax ? 'close' : 'off';
    checked.push({
      userId: person.id,
      name: person.name,
      fit,
      deltaE: Math.round(distance * 10) / 10,
      nearest: nearest.hex,
      outfit: main.hex,
    });
  }
  return { palette, people: checked, onCount: checked.filter((p) => p.fit === 'on').length, total: checked.length };
}
