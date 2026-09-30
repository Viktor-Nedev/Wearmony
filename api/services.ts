import { createDevVerifier, createSupabaseVerifier, type AuthVerifier } from './auth/verifier.js';
import type { Env } from './config/env.js';
import { createMemoryRepository } from './data/memory.js';
import type { Repository } from './data/repository.js';
import { createSupabaseRepository } from './data/supabase.js';
import { createGeminiExplainer, type Explainer } from './explain/gemini.js';
import type { PipelineDeps } from './render/pipeline.js';
import { createMemoryStorage, type MemoryStorage } from './storage/memory.js';
import type { MediaStorage } from './storage/storage.js';
import { createSupabaseStorage } from './storage/supabase.js';
import { createYouCamClient } from './youcam/live.js';
import { createLiveProvider } from './youcam/live-provider.js';
import { createMockProvider } from './youcam/mock.js';
import type { TryOnProvider } from './youcam/provider.js';

export interface Services {
  env: Env;
  repo: Repository;
  storage: MediaStorage;
  /** Set in memory mode, where the API serves media itself. */
  memoryStorage: MemoryStorage | null;
  auth: AuthVerifier;
  pipeline: PipelineDeps;
  explainer: Explainer | null;
  now: () => number;
}

export interface ServiceOverrides {
  repo?: Repository;
  storage?: MediaStorage;
  memoryStorage?: MemoryStorage | null;
  auth?: AuthVerifier;
  provider?: TryOnProvider;
  explainer?: Explainer | null;
  now?: () => number;
}

export function createServices(env: Env, overrides: ServiceOverrides = {}): Services {
  const now = overrides.now ?? Date.now;
  const supabase = env.DATA_MODE === 'supabase';

  const repo = overrides.repo ?? (supabase ? createSupabaseRepository(env.SUPABASE_URL!, env.SUPABASE_SECRET_KEY!) : createMemoryRepository());

  let memoryStorage: MemoryStorage | null = overrides.memoryStorage ?? null;
  let storage = overrides.storage;
  if (!storage) {
    if (supabase) {
      storage = createSupabaseStorage(env.SUPABASE_URL!, env.SUPABASE_SECRET_KEY!, env.SUPABASE_BUCKET);
    } else {
      memoryStorage ??= createMemoryStorage();
      storage = memoryStorage;
    }
  }

  const dev = createDevVerifier();
  const auth =
    overrides.auth ??
    (supabase
      ? createSupabaseVerifier(env.SUPABASE_URL!, env.SUPABASE_PUBLISHABLE_KEY!, {
          fallback: env.ALLOW_DEV_AUTH ? dev : undefined,
        })
      : dev);

  const mock = createMockProvider({ durationMs: env.MOCK_TRYON_SECONDS * 1000, now });
  const provider =
    overrides.provider ??
    (env.YOUCAM_MODE === 'live'
      ? createLiveProvider(createYouCamClient({ apiKey: env.YOUCAM_API_KEY!, baseUrl: env.YOUCAM_API_BASE! }), repo)
      : mock);

  const explainer =
    overrides.explainer !== undefined
      ? overrides.explainer
      : env.GEMINI_API_KEY
        ? createGeminiExplainer(env.GEMINI_API_KEY, env.GEMINI_MODEL)
        : null;

  return {
    env,
    repo,
    storage,
    memoryStorage,
    auth,
    explainer,
    now,
    pipeline: {
      repo,
      storage,
      provider,
      demoProvider: mock,
      now,
      limits: {
        perEvent: env.LEDGER_CAP_PER_EVENT,
        perParticipant: env.LEDGER_CAP_PER_PARTICIPANT,
        accountReserve: env.LEDGER_ACCOUNT_RESERVE,
      },
    },
  };
}
