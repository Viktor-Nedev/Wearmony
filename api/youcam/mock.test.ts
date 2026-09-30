import { describe, expect, it } from 'vitest';
import { createMockProvider, MOCK_FAIL_MARKER } from './mock.js';
import { UnknownTaskError, type TryOnRequest } from './types.js';

const DURATION = 4000;
const request: TryOnRequest = { kind: 'apparel', photoRef: 'photos/p1.jpg', itemRef: 'items/dress.jpg' };

function clock(start = 1_000_000) {
  let t = start;
  return { now: () => t, advance: (ms: number) => (t += ms) };
}

describe('mock try-on provider', () => {
  it('moves from queued to running to success', async () => {
    const c = clock();
    const provider = createMockProvider({ durationMs: DURATION, now: c.now });
    const { taskId } = await provider.start(request);

    expect((await provider.status(taskId)).state).toBe('queued');

    c.advance(DURATION / 2);
    const running = await provider.status(taskId);
    expect(running.state).toBe('running');
    expect(running.progress).toBeCloseTo(0.5);

    c.advance(DURATION);
    const done = await provider.status(taskId);
    expect(done).toMatchObject({ state: 'success', progress: 1, failure: null, mock: true });
  });

  it('simulates a silent failure for items marked as failing', async () => {
    const c = clock();
    const provider = createMockProvider({ durationMs: DURATION, now: c.now });
    const { taskId } = await provider.start({ ...request, itemRef: `${MOCK_FAIL_MARKER}-dress.jpg` });

    c.advance(DURATION);
    const status = await provider.status(taskId);
    expect(status.state).toBe('failed');
    expect(status.failure?.reason).toBe('garment_not_applied');
  });

  it('keeps no state, so a fresh provider can read an existing task', async () => {
    const c = clock();
    const { taskId } = await createMockProvider({ durationMs: DURATION, now: c.now }).start(request);
    c.advance(DURATION);
    const other = createMockProvider({ durationMs: DURATION, now: c.now });
    expect((await other.status(taskId)).state).toBe('success');
  });

  it('rejects unknown task ids', async () => {
    const provider = createMockProvider({ durationMs: DURATION });
    for (const id of ['', 'abc', 'mock.apparel.s', 'mock.shoes.s.abc.123', 'live.apparel.s.abc.123']) {
      await expect(provider.status(id)).rejects.toBeInstanceOf(UnknownTaskError);
    }
  });
});
