import { chroma, ciede2000, hexToLab, hueAngle, hueDistance, labToHex, type Lab } from './color.js';
import { HARMONY_CONFIG, type HarmonyConfig } from './config.js';
import type { DominantColor } from './extract.js';
import { nameColor, type ColorName } from './names.js';

export type Relation = 'matched' | 'near_miss' | 'complementary' | 'contrast';
export type Subject = 'outfit' | 'lips' | 'hair';

export interface HarmonyPersonInput {
  id: string;
  name: string;
  partnerId: string | null;
  /** Dominant colors of the chosen garment, largest first. */
  outfit: DominantColor[] | null;
  lips: string | null;
  hair: string | null;
}

export interface HarmonyColor {
  hex: string;
  name: ColorName;
}

export interface HarmonyFinding {
  scope: 'pair' | 'self';
  /** Person ids: two for a pair, one for a person's own colors. */
  people: string[];
  names: string[];
  subjects: [Subject, Subject];
  colors: [HarmonyColor, HarmonyColor];
  relation: Relation;
  deltaE: number;
  score: number;
  partners: boolean;
  /** One plain English sentence; the app builds localized text from the fields above. */
  sentence: string;
}

export interface HarmonyReport {
  /** Score of the weakest pair (0..100), or null if fewer than two colors are known. */
  groupScore: number | null;
  weakest: HarmonyFinding | null;
  /** All comparisons, weakest first. */
  findings: HarmonyFinding[];
  counts: Record<Relation, number>;
  /** Names of people without a garment in their look yet. */
  withoutOutfit: string[];
}

export function relate(a: Lab, b: Lab, config: HarmonyConfig = HARMONY_CONFIG) {
  const deltaE = ciede2000(a, b);
  const { scores } = config;

  if (deltaE < config.matchMax) return { relation: 'matched' as const, deltaE, score: scores.matched };

  if (deltaE < config.nearMissMax) {
    if (a[0] < config.darkPairLightnessMax && b[0] < config.darkPairLightnessMax) {
      return { relation: 'matched' as const, deltaE, score: scores.matched };
    }
    const center = (config.matchMax + config.nearMissMax) / 2;
    const halfWidth = (config.nearMissMax - config.matchMax) / 2;
    const edgeness = Math.abs(deltaE - center) / halfWidth;
    const score = Math.round(scores.nearMissWorst + (scores.nearMissBest - scores.nearMissWorst) * edgeness);
    return { relation: 'near_miss' as const, deltaE, score };
  }

  const bothChromatic = chroma(a) >= config.neutralChromaMax && chroma(b) >= config.neutralChromaMax;
  if (bothChromatic && hueDistance(hueAngle(a), hueAngle(b)) >= 180 - config.complementaryTolerance) {
    return { relation: 'complementary' as const, deltaE, score: scores.complementary };
  }
  return { relation: 'contrast' as const, deltaE, score: scores.contrast };
}

export function computeHarmony(people: HarmonyPersonInput[], config: HarmonyConfig = HARMONY_CONFIG): HarmonyReport {
  const findings: HarmonyFinding[] = [];
  const primary = (person: HarmonyPersonInput): Lab | null => {
    const top = person.outfit?.[0];
    return top ? (top.lab as Lab) : null;
  };

  for (let i = 0; i < people.length; i++) {
    const a = people[i]!;
    const aOutfit = primary(a);

    if (aOutfit) {
      for (const subject of ['lips', 'hair'] as const) {
        const hex = a[subject];
        if (!hex) continue;
        findings.push(finding('self', [a], [subject, 'outfit'], [hexToLab(hex), aOutfit], false, config));
      }
    }

    for (let j = i + 1; j < people.length; j++) {
      const b = people[j]!;
      const bOutfit = primary(b);
      if (!aOutfit || !bOutfit) continue;
      const partners = a.partnerId === b.id || b.partnerId === a.id;
      findings.push(finding('pair', [a, b], ['outfit', 'outfit'], [aOutfit, bOutfit], partners, config));
    }
  }

  findings.sort((x, y) => x.score - y.score || Number(y.partners) - Number(x.partners) || x.deltaE - y.deltaE);
  const counts: Record<Relation, number> = { matched: 0, near_miss: 0, complementary: 0, contrast: 0 };
  for (const f of findings) counts[f.relation]++;

  return {
    groupScore: findings[0]?.score ?? null,
    weakest: findings[0] ?? null,
    findings,
    counts,
    withoutOutfit: people.filter((p) => !primary(p)).map((p) => p.name),
  };
}

function finding(
  scope: 'pair' | 'self',
  people: HarmonyPersonInput[],
  subjects: [Subject, Subject],
  labs: [Lab, Lab],
  partners: boolean,
  config: HarmonyConfig,
): HarmonyFinding {
  const { relation, deltaE, score } = relate(labs[0], labs[1], config);
  const colors: [HarmonyColor, HarmonyColor] = [
    { hex: labToHex(labs[0]), name: nameColor(labs[0]) },
    { hex: labToHex(labs[1]), name: nameColor(labs[1]) },
  ];
  const result: Omit<HarmonyFinding, 'sentence'> = {
    scope,
    people: people.map((p) => p.id),
    names: people.map((p) => p.name),
    subjects,
    colors,
    relation,
    deltaE: Math.round(deltaE * 10) / 10,
    score,
    partners,
  };
  return { ...result, sentence: explain(result) };
}

const SUBJECT_LABEL: Record<Subject, string> = { outfit: 'outfit', lips: 'lip color', hair: 'hair color' };

export function explain(f: Omit<HarmonyFinding, 'sentence'>): string {
  const [ca, cb] = [f.colors[0].name.label, f.colors[1].name.label];
  const d = f.deltaE.toFixed(1);

  if (f.scope === 'self') {
    const who = f.names[0];
    const subject = SUBJECT_LABEL[f.subjects[0]];
    switch (f.relation) {
      case 'matched':
        return `${who}'s ${subject} matches the ${cb} outfit.`;
      case 'near_miss':
        return `${who}'s ${ca} ${subject} is close to, but not the same as, the ${cb} outfit (ΔE ${d}); match it or choose a clearly different shade.`;
      case 'complementary':
        return `${who}'s ${ca} ${subject} is complementary to the ${cb} outfit.`;
      case 'contrast':
        return `${who}'s ${ca} ${subject} stands apart from the ${cb} outfit, which reads as intentional.`;
    }
  }

  const [a, b] = f.names;
  switch (f.relation) {
    case 'matched':
      return `${a} and ${b} match: both wear ${ca}.`;
    case 'near_miss':
      return `${a}'s ${ca} and ${b}'s ${cb} are close but not the same shade (ΔE ${d}); side by side this can look like a mistake, so match them exactly or pick clearly different colors.`;
    case 'complementary':
      return `${a}'s ${ca} and ${b}'s ${cb} are complementary colors that set each other off.`;
    case 'contrast':
      return `${a}'s ${ca} and ${b}'s ${cb} are clearly different, which reads as intentional.`;
  }
}
