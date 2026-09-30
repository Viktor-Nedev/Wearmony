import { describe, expect, it } from 'vitest';
import { loadEnv } from './env.js';

describe('loadEnv', () => {
  it('defaults to mock mode with no configuration', () => {
    const env = loadEnv({});
    expect(env.YOUCAM_MODE).toBe('mock');
    expect(env.LEDGER_CAP_PER_EVENT).toBe(40);
    expect(env.MOCK_TRYON_SECONDS).toBe(4);
  });

  it('treats empty values as unset', () => {
    const env = loadEnv({ YOUCAM_MODE: '', YOUCAM_API_BASE: '', LEDGER_CAP_PER_EVENT: '' });
    expect(env.YOUCAM_MODE).toBe('mock');
    expect(env.YOUCAM_API_BASE).toBeUndefined();
    expect(env.LEDGER_CAP_PER_EVENT).toBe(40);
  });

  it('coerces numeric values', () => {
    expect(loadEnv({ LEDGER_CAP_PER_PARTICIPANT: '6' }).LEDGER_CAP_PER_PARTICIPANT).toBe(6);
  });

  it('refuses live mode without a key and base URL', () => {
    expect(() => loadEnv({ YOUCAM_MODE: 'live' })).toThrow(/requires YOUCAM_API_KEY/);
  });

  it('rejects an unknown mode', () => {
    expect(() => loadEnv({ YOUCAM_MODE: 'real' })).toThrow(/Invalid environment/);
  });
});
