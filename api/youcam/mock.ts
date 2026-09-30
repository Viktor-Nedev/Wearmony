import { createHash } from 'node:crypto';
import {
  UnknownTaskError,
  type TaskStatus,
  type TryOnKind,
  type TryOnProvider,
} from './types.js';

const PREFIX = 'mock';
const KINDS: readonly TryOnKind[] = ['apparel', 'makeup', 'hair'];

/** An itemRef starting with this marker simulates a silent failure. */
export const MOCK_FAIL_MARKER = 'mock-fail';

/** Share of the duration spent in the "queued" state. */
const QUEUED_SHARE = 0.15;

const NOT_APPLIED_MESSAGE =
  'The outfit was not applied to the photo. This often happens when the original clothing is dark or bulky; try a photo in lighter, fitted clothing.';

interface MockOptions {
  durationMs: number;
  now?: () => number;
}

/**
 * Stand-in for the YouCam API that makes zero network calls.
 * It keeps no state: the task id encodes the kind, the outcome and the start
 * time, so status checks work across separate serverless invocations.
 */
export function createMockProvider({ durationMs, now = Date.now }: MockOptions): TryOnProvider {
  return {
    mode: 'mock',

    async start(request) {
      const outcome = request.itemRef.startsWith(MOCK_FAIL_MARKER) ? 'f' : 's';
      const digest = createHash('sha256')
        .update(`${request.kind}|${request.photoRef}|${request.itemRef}`)
        .digest('hex')
        .slice(0, 12);
      return { taskId: [PREFIX, request.kind, outcome, now().toString(36), digest].join('.') };
    },

    async status(taskId) {
      const parsed = parseTaskId(taskId);
      if (!parsed) throw new UnknownTaskError(taskId);

      const elapsed = Math.max(0, now() - parsed.startedAt);
      const base: Omit<TaskStatus, 'state' | 'progress'> = {
        taskId,
        resultUrl: null,
        failure: null,
        mock: true,
      };

      if (elapsed < durationMs * QUEUED_SHARE) return { ...base, state: 'queued', progress: 0 };
      if (elapsed < durationMs) return { ...base, state: 'running', progress: elapsed / durationMs };
      if (parsed.outcome === 'f') {
        return {
          ...base,
          state: 'failed',
          progress: 1,
          failure: { reason: 'garment_not_applied', message: NOT_APPLIED_MESSAGE },
        };
      }
      return { ...base, state: 'success', progress: 1 };
    },
  };
}

function parseTaskId(taskId: string) {
  const [prefix, kind, outcome, started, digest, ...rest] = taskId.split('.');
  if (prefix !== PREFIX || rest.length > 0 || !digest) return null;
  if (!KINDS.includes(kind as TryOnKind)) return null;
  if (outcome !== 's' && outcome !== 'f') return null;
  const startedAt = parseInt(started ?? '', 36);
  if (!Number.isFinite(startedAt)) return null;
  return { kind: kind as TryOnKind, outcome, startedAt };
}
