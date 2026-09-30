import { describe, expect, it } from 'vitest';
import { loadEnv } from './env.js';

describe('loadEnv', () => {
  it('defaults to mock try-on and in-memory data', () => {
    const env = loadEnv({});
    expect(env).toMatchObject({
      YOUCAM_MODE: 'mock',
      DATA_MODE: 'memory',
      LEDGER_CAP_PER_EVENT: 40,
      MOCK_TRYON_SECONDS: 4,
      ALLOW_DEV_AUTH: false,
    });
  });

  it('treats empty values as unset and coerces numbers and flags', () => {
    const env = loadEnv({ YOUCAM_MODE: '', LEDGER_CAP_PER_EVENT: '', LEDGER_CAP_PER_PARTICIPANT: '6', ALLOW_DEV_AUTH: 'true' });
    expect(env.YOUCAM_MODE).toBe('mock');
    expect(env.LEDGER_CAP_PER_EVENT).toBe(40);
    expect(env.LEDGER_CAP_PER_PARTICIPANT).toBe(6);
    expect(env.ALLOW_DEV_AUTH).toBe(true);
  });

  it('refuses live mode without a key and Supabase mode without keys', () => {
    expect(() => loadEnv({ YOUCAM_MODE: 'live' })).toThrow(/requires YOUCAM_API_KEY/);
    expect(() => loadEnv({ DATA_MODE: 'supabase' })).toThrow(/requires SUPABASE_URL/);
  });

  it('rejects unknown modes', () => {
    expect(() => loadEnv({ YOUCAM_MODE: 'real' })).toThrow(/Invalid environment/);
  });
});
