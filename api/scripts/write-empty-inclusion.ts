// Rewrites api/generated/inclusion.ts for a project with no measurements yet.
// The kill-test runner overwrites it with real numbers after each run.
import { writeFileSync } from 'node:fs';
import { aggregateInclusion, renderInclusionModule } from '../inclusion/aggregate.js';

writeFileSync(
  new URL('../generated/inclusion.ts', import.meta.url),
  renderInclusionModule(aggregateInclusion([], 'YouCam AI Clothes V4.0 (cloth-v4)')),
);
console.log('api/generated/inclusion.ts written');
