import { hexToLab } from './color.js';
import { HARMONY_CONFIG, type HarmonyConfig } from './config.js';
import { computeHarmony, type HarmonyFinding, type HarmonyPersonInput, type Relation, type Subject } from './engine.js';
import type { DominantColor } from './extract.js';

// Fix suggestions: for a near-miss, try every catalogue item on the people involved,
// recompute the group's harmony with the same engine, and keep the swaps that remove
// the near-miss. Deterministic and explainable: each suggestion reports the relation
// and ΔE it would produce, the group score before and after, and the price change.

export type SuggestionItemType = 'garment' | 'makeup' | 'hair';

export interface SuggestionItem {
  id: string;
  type: SuggestionItemType;
  name: string;
  price: number;
  /** Garments: full_body, upper_body, ... A swap within the same category is preferred. */
  category?: string | null;
  /** Garments: dominant colors from the catalogue image. */
  dominantColors: DominantColor[] | null;
  /** Makeup and hair: the exact color. */
  colorHex: string | null;
}

export interface SuggestionLook {
  garmentId: string | null;
  makeupId: string | null;
  hairId: string | null;
  locked: boolean;
}

export interface FixSuggestion {
  /** The person who would change. */
  userId: string;
  name: string;
  itemId: string;
  itemName: string;
  itemType: SuggestionItemType;
  colorHex: string;
  price: number;
  /** New item price minus the price of the item it replaces. */
  priceDelta: number;
  /** The fixed comparison after the swap. */
  relationAfter: Relation;
  deltaEAfter: number;
  /** For a pair: the other person in it. */
  otherUserId: string | null;
  otherName: string | null;
  groupScoreBefore: number | null;
  groupScoreAfter: number | null;
  /** Near-misses left in the whole group after the swap. */
  warningsAfter: number;
  /** The person's look stays within the per-person cap (always true without a cap). */
  withinBudget: boolean;
}

export interface SuggestInput {
  people: HarmonyPersonInput[];
  looks: Map<string, SuggestionLook>;
  items: SuggestionItem[];
  perPersonCap: number | null;
  /** The near-miss to fix. */
  target: HarmonyFinding;
  limit?: number;
  config?: HarmonyConfig;
}

const SLOT: Record<SuggestionItemType, keyof Omit<SuggestionLook, 'locked'>> = {
  garment: 'garmentId',
  makeup: 'makeupId',
  hair: 'hairId',
};

/** Which item type changes which compared subject. */
const TYPE_FOR_SUBJECT: Record<Subject, SuggestionItemType> = { outfit: 'garment', lips: 'makeup', hair: 'hair' };

/** The weakest near-miss overall, or the weakest one involving `userId` (and `otherId`, for one pair). */
export function pickTarget(findings: HarmonyFinding[], userId?: string, otherId?: string): HarmonyFinding | null {
  return (
    findings.find(
      (f) =>
        f.relation === 'near_miss' &&
        (userId === undefined || f.people.includes(userId)) &&
        (otherId === undefined || f.people.includes(otherId)),
    ) ?? null
  );
}

function sameComparison(a: HarmonyFinding, b: HarmonyFinding): boolean {
  return a.scope === b.scope && a.people.join('|') === b.people.join('|') && a.subjects.join('|') === b.subjects.join('|');
}

function wear(person: HarmonyPersonInput, item: SuggestionItem): HarmonyPersonInput {
  switch (item.type) {
    case 'garment':
      return { ...person, outfit: item.dominantColors };
    case 'makeup':
      return { ...person, lips: item.colorHex };
    case 'hair':
      return { ...person, hair: item.colorHex };
  }
}

function usable(item: SuggestionItem): boolean {
  if (item.type === 'garment') return Boolean(item.dominantColors?.length);
  if (!item.colorHex) return false;
  try {
    hexToLab(item.colorHex);
    return true;
  } catch {
    return false;
  }
}

export function suggestFixes(input: SuggestInput): FixSuggestion[] {
  const config = input.config ?? HARMONY_CONFIG;
  const { target, people, looks, perPersonCap } = input;
  if (target.relation !== 'near_miss') return [];
  const before = computeHarmony(people, config);
  const prices = new Map(input.items.map((item) => [item.id, item.price]));
  const categories = new Map(input.items.map((item) => [item.id, item.category ?? null]));

  // Who can change: the people in the comparison whose look is not locked.
  // For a person's own colors, only the lip or hair color is swapped (the outfit stays).
  const movers = target.people.filter((id) => !looks.get(id)?.locked);
  const type = target.scope === 'self' ? TYPE_FOR_SUBJECT[target.subjects[0]] : 'garment';

  const found: (FixSuggestion & { rank: number[] })[] = [];
  for (const userId of movers) {
    const index = people.findIndex((p) => p.id === userId);
    if (index < 0) continue;
    const look = looks.get(userId) ?? { garmentId: null, makeupId: null, hairId: null, locked: false };
    const currentId = look[SLOT[type]];
    const currentPrice = currentId ? (prices.get(currentId) ?? 0) : 0;
    const currentCategory = currentId ? categories.get(currentId) : undefined;
    const lookTotal = [look.garmentId, look.makeupId, look.hairId].reduce(
      (sum, id) => sum + (id ? (prices.get(id) ?? 0) : 0),
      0,
    );

    for (const item of input.items) {
      if (item.type !== type || item.id === currentId || !usable(item)) continue;
      const trial = people.map((p, i) => (i === index ? wear(p, item) : p));
      const after = computeHarmony(trial, config);
      const fixed = after.findings.find((f) => sameComparison(f, target));
      if (!fixed || fixed.relation === 'near_miss') continue;

      const priceDelta = Math.round((item.price - currentPrice) * 100) / 100;
      const withinBudget = perPersonCap === null || lookTotal + priceDelta <= perPersonCap + 1e-9;
      const warningsAfter = after.counts.near_miss;
      const otherIndex = target.people.indexOf(userId) === 0 ? 1 : 0;
      const other = target.scope === 'pair' ? target.names[otherIndex]! : null;
      const otherUserId = target.scope === 'pair' ? target.people[otherIndex]! : null;
      found.push({
        userId,
        name: people[index]!.name,
        itemId: item.id,
        itemName: item.name,
        itemType: item.type,
        colorHex: item.type === 'garment' ? item.dominantColors![0]!.hex : item.colorHex!,
        price: item.price,
        priceDelta,
        relationAfter: fixed.relation,
        deltaEAfter: fixed.deltaE,
        otherUserId,
        otherName: other,
        groupScoreBefore: before.groupScore,
        groupScoreAfter: after.groupScore,
        warningsAfter,
        withinBudget,
        // Fewest near-misses left, then within budget, then the best group score,
        // then the same kind of garment (a dress for a dress), then the cheapest.
        rank: [
          warningsAfter,
          withinBudget ? 0 : 1,
          -(after.groupScore ?? 0),
          currentCategory != null && (item.category ?? null) !== currentCategory ? 1 : 0,
          priceDelta,
        ],
      });
    }
  }

  found.sort((a, b) => {
    for (let i = 0; i < a.rank.length; i++) {
      if (a.rank[i] !== b.rank[i]) return a.rank[i]! - b.rank[i]!;
    }
    return a.itemName.localeCompare(b.itemName);
  });

  // At most two ideas per person, so both people in a pair get options.
  const limit = input.limit ?? 3;
  const perPerson = new Map<string, number>();
  const picked: FixSuggestion[] = [];
  for (const { rank: _rank, ...suggestion } of found) {
    const count = perPerson.get(suggestion.userId) ?? 0;
    if (count >= 2) continue;
    perPerson.set(suggestion.userId, count + 1);
    picked.push(suggestion);
    if (picked.length >= limit) break;
  }
  return picked;
}
