// Local development server: runs the same app as the Vercel function,
// without needing a Vercel account. Reads ../.env if present.
import { serve } from '@hono/node-server';
import { buildApp } from './http/app.js';
import { loadEnv } from './config/env.js';

try {
  process.loadEnvFile(new URL('../.env', import.meta.url));
} catch {
  // No .env file: defaults apply (mock mode).
}

const port = Number(process.env.PORT ?? 8787);
const { YOUCAM_MODE } = loadEnv();

serve({ fetch: buildApp().fetch, port }, (info) => {
  console.log(`Wearmony API on http://localhost:${info.port}/api (YouCam mode: ${YOUCAM_MODE})`);
});
