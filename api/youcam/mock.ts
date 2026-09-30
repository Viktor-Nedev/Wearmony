import sharp from 'sharp';
import type { GarmentCategory, TryOnKind } from '../domain/types.js';
import type { TryOnInput, TryOnProvider, TryOnResult } from './provider.js';

const KINDS: readonly TryOnKind[] = ['apparel', 'makeup', 'hair'];

/** Vertical band (share of image height) a simulated garment covers. */
const GARMENT_BAND: Record<GarmentCategory, [number, number]> = {
  full_body: [0.3, 0.96],
  upper_body: [0.3, 0.62],
  lower_body: [0.56, 0.96],
  outer: [0.28, 0.72],
};
/** Share of the duration spent before any progress is reported. */
const QUEUED_SHARE = 0.15;

export const MOCK_NOT_APPLIED_MESSAGE =
  'The outfit was not applied to the photo. This often happens when the clothing on the photo is dark or bulky; try a photo in lighter, fitted clothing.';

interface MockOptions {
  durationMs: number;
  now?: () => number;
}

/**
 * Try-on provider that makes zero network calls. Results are simulated
 * overlays with a striped pattern, and the app labels them as simulated.
 * It keeps no state: the task id encodes kind, outcome and start time, so it
 * works across separate serverless invocations.
 */
export function createMockProvider({ durationMs, now = Date.now }: MockOptions): TryOnProvider {
  return {
    mode: 'mock',
    typicalDurationMs: durationMs,
    cost: () => 0,
    async balance() {
      return null;
    },

    async start(input) {
      const outcome = input.simulateFailure ? 'f' : 's';
      return ['mock', input.kind, outcome, now().toString(36), input.imageHash.slice(0, 12)].join('.');
    },

    async check(taskId, loadInput): Promise<TryOnResult> {
      const parsed = parseTaskId(taskId);
      if (!parsed) return { state: 'failed', reason: 'provider_error', code: 'unknown_task', message: `Unknown task ${taskId}` };

      const elapsed = Math.max(0, now() - parsed.startedAt);
      if (elapsed < durationMs) {
        const progress = elapsed < durationMs * QUEUED_SHARE ? 0 : elapsed / durationMs;
        return { state: 'running', progress };
      }
      if (parsed.outcome === 'f') {
        return { state: 'failed', reason: 'garment_not_applied', code: 'mock_failure', message: MOCK_NOT_APPLIED_MESSAGE };
      }
      return { state: 'success', image: await simulateTryOn(await loadInput()) };
    },
  };
}

/** Draws the chosen color over the photo, with stripes that mark the image as simulated. */
export async function simulateTryOn(input: TryOnInput): Promise<Buffer> {
  const meta = await sharp(input.image).metadata();
  const w = meta.width ?? 768;
  const h = meta.height ?? 1024;
  const stripes = `<pattern id="s" width="24" height="24" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
      <rect width="12" height="24" fill="#FFFFFF" fill-opacity="0.22"/></pattern>`;

  let shapes = '';
  if (input.kind === 'apparel') {
    const color = input.garment?.colorHex ?? '#8A8A8A';
    const [top, bottom] = GARMENT_BAND[input.garment?.category ?? 'full_body'];
    const y = h * top;
    const height = h * (bottom - top);
    shapes = `<rect x="${w * 0.22}" y="${y}" width="${w * 0.56}" height="${height}" rx="${w * 0.06}" fill="${color}" fill-opacity="0.86"/>
      <rect x="${w * 0.22}" y="${y}" width="${w * 0.56}" height="${height}" rx="${w * 0.06}" fill="url(#s)"/>`;
  } else if (input.kind === 'hair') {
    shapes = `<rect x="${w * 0.2}" y="0" width="${w * 0.6}" height="${h * 0.2}" rx="${w * 0.1}" fill="${input.colorHex}" fill-opacity="0.55"/>
      <rect x="${w * 0.2}" y="0" width="${w * 0.6}" height="${h * 0.2}" rx="${w * 0.1}" fill="url(#s)"/>`;
  } else {
    const r = w * 0.07;
    shapes = `<circle cx="${w - r * 1.6}" cy="${h - r * 1.6}" r="${r}" fill="${input.colorHex}" stroke="#FFFFFF" stroke-width="${r * 0.18}"/>`;
  }

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><defs>${stripes}</defs>${shapes}</svg>`;
  return sharp(input.image)
    .rotate()
    .composite([{ input: Buffer.from(svg), top: 0, left: 0 }])
    .jpeg({ quality: 88 })
    .toBuffer();
}

function parseTaskId(taskId: string) {
  const [prefix, kind, outcome, started, digest, ...rest] = taskId.split('.');
  if (prefix !== 'mock' || rest.length > 0 || !digest) return null;
  if (!KINDS.includes(kind as TryOnKind)) return null;
  if (outcome !== 's' && outcome !== 'f') return null;
  const startedAt = parseInt(started ?? '', 36);
  if (!Number.isFinite(startedAt)) return null;
  return { kind: kind as TryOnKind, outcome, startedAt };
}
