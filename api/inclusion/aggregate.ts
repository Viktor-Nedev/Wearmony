import type { InclusionGroup, InclusionResults } from '../generated/inclusion.js';

/** One evaluated try-on, as recorded by eval/kill-tests/run.ts. */
export interface EvalRun {
  person: string;
  pose: 'standing' | 'seated';
  feature: string;
  test: string;
  state: 'success' | 'error' | 'rejected' | 'timeout';
  errorCode: string | null;
  latencyMs: number;
  ranAt: string;
  review: { garmentApplied: boolean | null; identityKept: boolean | null };
}

export const BASE_NOTES = [
  'The YouCam AI Clothes documentation asks for a person standing (no sitting or crouching); this evaluation measures what that means for seated participants.',
  '"Applied" counts renders a human reviewer did not reject; "silent failures" are renders returned without the garment.',
];

/** Engine error that means "result too similar to the source": the garment was not applied. */
const NOT_APPLIED_CODES = new Set(['error_editing_failed']);

export function framingOf(run: EvalRun): InclusionGroup['framing'] {
  return run.test.includes('mitigation') ? 'upper_body_fallback' : 'as_catalogued';
}

/** Turns raw apparel runs into the published table. Nothing is estimated. */
export function aggregateInclusion(runs: EvalRun[], engine: string): InclusionResults {
  const apparel = runs.filter((run) => run.feature.startsWith('cloth'));
  const order: [InclusionGroup['pose'], InclusionGroup['framing']][] = [
    ['standing', 'as_catalogued'],
    ['seated', 'as_catalogued'],
    ['seated', 'upper_body_fallback'],
    ['standing', 'upper_body_fallback'],
  ];

  const groups: InclusionGroup[] = [];
  for (const [pose, framing] of order) {
    const group = apparel.filter((run) => run.pose === pose && framingOf(run) === framing);
    if (group.length === 0) continue;
    const notApplied = (run: EvalRun) =>
      (run.state === 'success' && run.review.garmentApplied === false) ||
      (run.errorCode !== null && NOT_APPLIED_CODES.has(run.errorCode));
    const success = group.filter((run) => run.state === 'success' && run.review.garmentApplied !== false);
    const reviewed = group.filter((run) => run.review.identityKept !== null);
    groups.push({
      pose,
      framing,
      runs: group.length,
      success: success.length,
      silentFailures: group.filter(notApplied).length,
      errors: group.filter((run) => run.state !== 'success' && !notApplied(run)).length,
      identityDrift: reviewed.length ? reviewed.filter((run) => run.review.identityKept === false).length : null,
      medianLatencySeconds: median(success.map((run) => run.latencyMs / 1000)),
    });
  }

  const people = new Set(apparel.map((run) => run.person));
  const seatedPeople = new Set(apparel.filter((run) => run.pose === 'seated').map((run) => run.person));
  const measuredAt = apparel.map((run) => run.ranAt).sort().at(-1) ?? null;
  const notes = apparel.length
    ? [
        `${apparel.length} apparel renders of ${people.size} people (${seatedPeople.size} seated). A small sample: read the numbers as indicative, not as a benchmark.`,
        ...BASE_NOTES,
      ]
    : [...BASE_NOTES];

  const sample = apparel.length ? { renders: apparel.length, people: people.size, seated: seatedPeople.size } : null;
  return { measuredAt, engine, groups, sample, notes };
}

export function renderInclusionModule(results: InclusionResults): string {
  const source = readTypesBlock();
  return `${source}\nexport const INCLUSION_RESULTS: InclusionResults = ${JSON.stringify(results, null, 2)};\n`;
}

function median(values: number[]): number | null {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  const value = sorted.length % 2 ? sorted[mid]! : (sorted[mid - 1]! + sorted[mid]!) / 2;
  return Math.round(value * 10) / 10;
}

/** The header and types of api/generated/inclusion.ts, kept identical on every write. */
function readTypesBlock(): string {
  return `// Measured inclusion results, written by eval/kill-tests/run.ts from
// eval/results/kill-tests.json. Do not edit by hand; nothing here is estimated.

export interface InclusionGroup {
  pose: 'standing' | 'seated';
  /** How the garment was applied: as catalogued, or the upper-body fallback for seated photos. */
  framing: 'as_catalogued' | 'upper_body_fallback';
  runs: number;
  /** Render returned and the garment was applied (human-reviewed where available). */
  success: number;
  /** Render returned but the garment was not applied. */
  silentFailures: number;
  /** Engine refused or failed the task. */
  errors: number;
  /** Runs where a human reviewer saw a different face. Null until reviewed. */
  identityDrift: number | null;
  medianLatencySeconds: number | null;
}

export interface InclusionResults {
  measuredAt: string | null;
  engine: string;
  groups: InclusionGroup[];
  /** How many apparel renders, people and seated people the numbers come from. */
  sample: { renders: number; people: number; seated: number } | null;
  /** The same facts as plain English sentences; the app localizes its own. */
  notes: string[];
}
`;
}
