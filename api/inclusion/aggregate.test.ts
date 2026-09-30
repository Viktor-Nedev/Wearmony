import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { INCLUSION_RESULTS } from '../generated/inclusion.js';
import { aggregateInclusion, renderInclusionModule, type EvalRun } from './aggregate.js';

function run(overrides: Partial<EvalRun>): EvalRun {
  return {
    person: 'p1',
    pose: 'standing',
    feature: 'cloth-v4',
    test: 'identity',
    state: 'success',
    errorCode: null,
    latencyMs: 20_000,
    ranAt: '2026-10-02T10:00:00.000Z',
    review: { garmentApplied: null, identityKept: null },
    ...overrides,
  };
}

describe('aggregateInclusion', () => {
  it('separates standing, seated and the upper-body fallback', () => {
    const results = aggregateInclusion(
      [
        run({ person: 'p1', latencyMs: 18_000 }),
        run({ person: 'p1', latencyMs: 22_000, review: { garmentApplied: true, identityKept: true } }),
        run({ person: 'p2', pose: 'seated', test: 'seated', state: 'error', errorCode: 'error_pose' }),
        run({ person: 'p2', pose: 'seated', test: 'seated', review: { garmentApplied: false, identityKept: true } }),
        run({ person: 'p2', pose: 'seated', test: 'seated', state: 'error', errorCode: 'error_editing_failed' }),
        run({ person: 'p2', pose: 'seated', test: 'seated-mitigation', latencyMs: 30_000 }),
        run({ person: 'p1', feature: 'hair-color', test: 'hair' }),
      ],
      'cloth-v4',
    );

    expect(results.groups).toEqual([
      { pose: 'standing', framing: 'as_catalogued', runs: 2, success: 2, silentFailures: 0, errors: 0, identityDrift: 0, medianLatencySeconds: 20 },
      { pose: 'seated', framing: 'as_catalogued', runs: 3, success: 0, silentFailures: 2, errors: 1, identityDrift: 0, medianLatencySeconds: null },
      { pose: 'seated', framing: 'upper_body_fallback', runs: 1, success: 1, silentFailures: 0, errors: 0, identityDrift: null, medianLatencySeconds: 30 },
    ]);
    expect(results.notes[0]).toContain('6 apparel renders of 2 people (1 seated)');
    expect(results.measuredAt).toBe('2026-10-02T10:00:00.000Z');
  });

  it('reports no measurements honestly', () => {
    const results = aggregateInclusion([], 'cloth-v4');
    expect(results).toMatchObject({ measuredAt: null, groups: [] });
    expect(results.notes[0]).toMatch(/^No measurements yet/);
  });

  it('matches the committed module when nothing has been measured', () => {
    const committed = readFileSync(new URL('../generated/inclusion.ts', import.meta.url), 'utf8');
    if (INCLUSION_RESULTS.groups.length === 0) {
      expect(renderInclusionModule(aggregateInclusion([], INCLUSION_RESULTS.engine))).toBe(committed.replace(/\r\n/g, '\n'));
    }
  });
});
