import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import { createMockProvider, MOCK_NOT_APPLIED_MESSAGE } from './mock.js';
import type { TryOnInput } from './provider.js';

const DURATION = 4000;

async function input(overrides: Partial<TryOnInput> = {}): Promise<TryOnInput> {
  const image = await sharp({ create: { width: 300, height: 400, channels: 3, background: '#DADDE2' } }).jpeg().toBuffer();
  return {
    kind: 'apparel',
    image,
    imageHash: 'a1b2c3d4e5f6a7b8',
    garment: { image, hash: 'g1', category: 'full_body', colorHex: '#B0304A' },
    ...overrides,
  };
}

function clock(start = 1_000_000) {
  let t = start;
  return { now: () => t, advance: (ms: number) => (t += ms) };
}

describe('mock try-on provider', () => {
  it('reports progress, then a simulated image of the same size', async () => {
    const c = clock();
    const provider = createMockProvider({ durationMs: DURATION, now: c.now });
    const source = await input();
    const taskId = await provider.start(source);

    expect(await provider.check(taskId, async () => source)).toEqual({ state: 'running', progress: 0 });
    c.advance(DURATION / 2);
    expect(await provider.check(taskId, async () => source)).toEqual({ state: 'running', progress: 0.5 });

    c.advance(DURATION);
    const done = await provider.check(taskId, async () => source);
    expect(done.state).toBe('success');
    if (done.state !== 'success') return;
    const meta = await sharp(done.image).metadata();
    expect([meta.width, meta.height]).toEqual([300, 400]);
    // The garment color now covers the middle of the image.
    const { data } = await sharp(done.image).extract({ left: 150, top: 250, width: 1, height: 1 }).raw().toBuffer({ resolveWithObject: true });
    expect(data[0]).toBeGreaterThan(data[2]! + 40);
  });

  it('simulates a silent failure when asked', async () => {
    const c = clock();
    const provider = createMockProvider({ durationMs: DURATION, now: c.now });
    const source = await input({ simulateFailure: true });
    const taskId = await provider.start(source);
    c.advance(DURATION);
    expect(await provider.check(taskId, async () => source)).toEqual({
      state: 'failed',
      reason: 'garment_not_applied',
      code: 'mock_failure',
      message: MOCK_NOT_APPLIED_MESSAGE,
    });
  });

  it('keeps no state, so another instance can read a task', async () => {
    const c = clock();
    const source = await input({ kind: 'hair', colorHex: '#6B2A3A' });
    const taskId = await createMockProvider({ durationMs: DURATION, now: c.now }).start(source);
    c.advance(DURATION);
    const other = createMockProvider({ durationMs: DURATION, now: c.now });
    expect((await other.check(taskId, async () => source)).state).toBe('success');
  });

  it('rejects unknown task ids and costs nothing', async () => {
    const provider = createMockProvider({ durationMs: DURATION });
    const result = await provider.check('mock.shoes.s.abc.123', async () => input());
    expect(result).toMatchObject({ state: 'failed', reason: 'provider_error' });
    expect(provider.cost('apparel')).toBe(0);
    expect(await provider.balance()).toBeNull();
  });
});
