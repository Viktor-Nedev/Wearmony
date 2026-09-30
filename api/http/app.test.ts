import { describe, expect, it } from 'vitest';
import { loadEnv } from '../config/env.js';
import { createMockProvider } from '../youcam/mock.js';
import { createApp } from './app.js';

function setup(envSource: Record<string, string> = {}) {
  let t = 1_000_000;
  const tryOn = createMockProvider({ durationMs: 4000, now: () => t });
  const app = createApp({ env: loadEnv(envSource), tryOn });
  return { app, advance: (ms: number) => (t += ms) };
}

const validBody = { kind: 'apparel', photoRef: 'photos/p1.jpg', itemRef: 'items/dress.jpg' };

function postJson(body: unknown, headers: Record<string, string> = {}) {
  return {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  };
}

describe('HTTP API', () => {
  it('reports health and the YouCam mode', async () => {
    const res = await setup().app.request('/api/health');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ ok: true, youcamMode: 'mock' });
  });

  it('starts a try-on and reports its status', async () => {
    const { app, advance } = setup();
    const start = await app.request('/api/tryon', postJson(validBody));
    expect(start.status).toBe(202);
    const { taskId, mock } = (await start.json()) as { taskId: string; mock: boolean };
    expect(mock).toBe(true);

    advance(5000);
    const status = await app.request(`/api/tryon/${taskId}`);
    expect(status.status).toBe(200);
    expect(await status.json()).toMatchObject({ taskId, state: 'success', mock: true });
  });

  it('rejects an invalid try-on request', async () => {
    const { app } = setup();
    expect((await app.request('/api/tryon', postJson({ kind: 'shoes' }))).status).toBe(400);
    expect((await app.request('/api/tryon', { method: 'POST', body: 'not json' })).status).toBe(400);
  });

  it('returns 404 for unknown tasks and routes', async () => {
    const { app } = setup();
    expect((await app.request('/api/tryon/nope')).status).toBe(404);
    expect((await app.request('/api/nothing-here')).status).toBe(404);
  });

  it('allows localhost origins by default and nothing else', async () => {
    const { app } = setup();
    const local = await app.request('/api/health', { headers: { origin: 'http://localhost:5173' } });
    expect(local.headers.get('access-control-allow-origin')).toBe('http://localhost:5173');
    const other = await app.request('/api/health', { headers: { origin: 'https://example.com' } });
    expect(other.headers.get('access-control-allow-origin')).toBeNull();
  });

  it('uses the configured origin allow-list when set', async () => {
    const { app } = setup({ CORS_ORIGINS: 'https://wearmony.web.app' });
    const allowed = await app.request('/api/health', { headers: { origin: 'https://wearmony.web.app' } });
    expect(allowed.headers.get('access-control-allow-origin')).toBe('https://wearmony.web.app');
    const local = await app.request('/api/health', { headers: { origin: 'http://localhost:5173' } });
    expect(local.headers.get('access-control-allow-origin')).toBeNull();
  });
});
