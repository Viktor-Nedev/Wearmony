import type { Env } from '../config/env.js';
import { createMockProvider } from './mock.js';
import type { TryOnProvider } from './types.js';

export * from './types.js';

export function createTryOnProvider(env: Env): TryOnProvider {
  if (env.YOUCAM_MODE === 'mock') {
    return createMockProvider({ durationMs: env.MOCK_TRYON_SECONDS * 1000 });
  }
  throw new Error('The live YouCam client is not implemented yet. Set YOUCAM_MODE=mock.');
}
