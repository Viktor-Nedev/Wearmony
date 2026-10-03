// Measured inclusion results, written by eval/kill-tests/run.ts from
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

export const INCLUSION_RESULTS: InclusionResults = {
  "measuredAt": null,
  "engine": "YouCam AI Clothes V4.0 (cloth-v4)",
  "groups": [],
  "sample": null,
  "notes": [
    "The YouCam AI Clothes documentation asks for a person standing (no sitting or crouching); this evaluation measures what that means for seated participants.",
    "\"Applied\" counts renders a human reviewer did not reject; \"silent failures\" are renders returned without the garment."
  ]
};
