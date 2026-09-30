import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { z } from 'zod';
import { loadEnv, type Env } from '../config/env.js';
import { createTryOnProvider, UnknownTaskError, type TryOnProvider } from '../youcam/index.js';

interface AppDeps {
  env: Env;
  tryOn: TryOnProvider;
}

const TryOnBody = z.object({
  kind: z.enum(['apparel', 'makeup', 'hair']),
  photoRef: z.string().min(1),
  itemRef: z.string().min(1),
  garmentCategory: z.enum(['upper_body', 'lower_body', 'full_body', 'auto']).optional(),
});

const LOCALHOST_ORIGIN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

export function corsOrigin(configured: string | undefined) {
  const allowList = (configured ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  return (origin: string) => {
    if (allowList.length > 0) return allowList.includes(origin) ? origin : null;
    return LOCALHOST_ORIGIN.test(origin) ? origin : null;
  };
}

export function createApp({ env, tryOn }: AppDeps) {
  const app = new Hono().basePath('/api');

  app.use('*', cors({ origin: corsOrigin(env.CORS_ORIGINS) }));

  app.get('/health', (c) => c.json({ ok: true, youcamMode: tryOn.mode }));

  app.post('/tryon', async (c) => {
    const parsed = TryOnBody.safeParse(await c.req.json().catch(() => null));
    if (!parsed.success) {
      return c.json({ error: 'invalid_request', issues: parsed.error.issues }, 400);
    }
    const { taskId } = await tryOn.start(parsed.data);
    return c.json({ taskId, mock: tryOn.mode === 'mock' }, 202);
  });

  app.get('/tryon/:taskId', async (c) => c.json(await tryOn.status(c.req.param('taskId'))));

  app.notFound((c) => c.json({ error: 'not_found' }, 404));

  app.onError((err, c) => {
    if (err instanceof UnknownTaskError) return c.json({ error: 'unknown_task' }, 404);
    console.error(err);
    return c.json({ error: 'internal_error' }, 500);
  });

  return app;
}

/** Builds the app from process environment. Shared by the Vercel entry and the local dev server. */
export function buildApp(source: Record<string, string | undefined> = process.env) {
  const env = loadEnv(source);
  return createApp({ env, tryOn: createTryOnProvider(env) });
}
