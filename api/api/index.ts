// The single Vercel function. vercel.json rewrites every /api/* path here and
// the Hono router in http/app.ts dispatches it.
import { handle } from 'hono/vercel';
import { buildApp } from '../http/app.js';

const handler = handle(buildApp());

export const GET = handler;
export const POST = handler;
export const PUT = handler;
export const PATCH = handler;
export const DELETE = handler;
export const OPTIONS = handler;
