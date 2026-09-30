import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { loadEnv } from '../config/env.js';
import { createServices, type Services } from '../services.js';
import { HttpError, type AppEnv } from './context.js';
import { board } from './routes/board.js';
import { catalogue } from './routes/catalogue.js';
import { events } from './routes/events.js';
import { looks } from './routes/looks.js';
import { publicRoutes } from './routes/public.js';

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

export function createApp(services: Services) {
  const app = new Hono<AppEnv>().basePath('/api');

  app.use(
    '*',
    cors({
      origin: corsOrigin(services.env.CORS_ORIGINS),
      allowHeaders: ['Authorization', 'Content-Type'],
      allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      maxAge: 600,
    }),
  );
  app.use('*', async (c, next) => {
    c.set('services', services);
    await next();
  });

  app.route('/', publicRoutes);
  app.route('/', events);
  app.route('/', catalogue);
  app.route('/', looks);
  app.route('/', board);

  app.notFound((c) => c.json({ error: 'not_found', message: 'Not found.' }, 404));
  app.onError((err, c) => {
    if (err instanceof HttpError) {
      return c.json({ error: err.code, message: err.message, details: err.details ?? null }, err.status);
    }
    console.error(err);
    return c.json({ error: 'internal_error', message: 'Something went wrong.' }, 500);
  });

  return app;
}

/** Builds the app from the process environment. Shared by the Vercel entry and the local dev server. */
export function buildApp(source: Record<string, string | undefined> = process.env) {
  return createApp(createServices(loadEnv(source)));
}
