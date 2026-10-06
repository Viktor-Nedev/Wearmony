import { HARMONY_CONFIG, type HarmonyConfig } from './config.js';
import { computeHarmony, type HarmonyPersonInput, type Relation } from './engine.js';
import type { DominantColor } from './extract.js';

export interface PollOptionInput {
  id: string;
  dominantColors: DominantColor[] | null;
}

export interface PollOptionHarmony {
  itemId: string;
  /** Group score (weakest pair) if the person wore this garment; null when it cannot be compared yet. */
  groupScore: number | null;
  /** Near-misses in the whole group with this garment. */
  warnings: number;
  /** Near-misses this garment itself takes part in (with others or the person's own lips and hair). */
  ownWarnings: number;
  /** How the garment relates to the partner's outfit, if the person has a partner with an outfit. */
  partnerRelation: Relation | null;
}

/**
 * What each poll option would do to the group's harmony: the same engine and
 * thresholds as the harmony check, run once per option with the owner wearing it.
 * Options without extracted colors are reported with no score rather than guessed.
 */
export function scorePollOptions(
  people: HarmonyPersonInput[],
  ownerId: string,
  options: PollOptionInput[],
  config: HarmonyConfig = HARMONY_CONFIG,
): PollOptionHarmony[] {
  const index = people.findIndex((p) => p.id === ownerId);
  return options.map((option) => {
    if (index < 0 || !option.dominantColors?.length) {
      return { itemId: option.id, groupScore: null, warnings: 0, ownWarnings: 0, partnerRelation: null };
    }
    const owner = { ...people[index]!, outfit: option.dominantColors };
    const report = computeHarmony(
      people.map((p, i) => (i === index ? owner : p)),
      config,
    );
    // Every comparison that includes the owner includes the garment: pairs compare
    // outfits, and a person's own lips and hair are compared with their outfit.
    const own = report.findings.filter((f) => f.people.includes(ownerId));
    const partner = own.find((f) => f.scope === 'pair' && f.partners);
    return {
      itemId: option.id,
      groupScore: report.groupScore,
      warnings: report.counts.near_miss,
      ownWarnings: own.filter((f) => f.relation === 'near_miss').length,
      partnerRelation: partner?.relation ?? null,
    };
  });
}
