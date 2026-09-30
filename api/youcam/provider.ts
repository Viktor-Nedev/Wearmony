import type { FailureReason, GarmentCategory, TryOnKind } from '../domain/types.js';

export interface TryOnInput {
  kind: TryOnKind;
  /** Normalized JPEG of the participant, or the previous step's result. */
  image: Buffer;
  imageHash: string;
  garment?: { image: Buffer; hash: string; category: GarmentCategory; colorHex: string | null };
  /** Lip color (makeup) or hair color. */
  colorHex?: string;
  /** Mock provider only: simulate a silent failure. */
  simulateFailure?: boolean;
}

export type TryOnResult =
  | { state: 'running'; progress: number }
  | { state: 'success'; image: Buffer }
  | { state: 'failed'; reason: FailureReason; code: string | null; message: string };

/** One try-on engine. The pipeline never knows whether it talks to YouCam or the mock. */
export interface TryOnProvider {
  readonly mode: 'mock' | 'live';
  /** Typical time one task takes, used to estimate progress between status checks. */
  readonly typicalDurationMs: number;
  /** Units one task of this kind costs. */
  cost(kind: TryOnKind): number;
  /** Starts a task and returns the provider's task id. */
  start(input: TryOnInput): Promise<string>;
  /** Checks a task. `loadInput` is only called by providers that need the inputs again. */
  check(taskId: string, loadInput: () => Promise<TryOnInput>): Promise<TryOnResult>;
  /** Remaining account units, or null when there is no account (mock). */
  balance(): Promise<number | null>;
}

/** Raised by `start` when the provider refuses the task outright. */
export class TryOnStartError extends Error {
  constructor(
    readonly reason: FailureReason,
    readonly code: string | null,
    message: string,
  ) {
    super(message);
    this.name = 'TryOnStartError';
  }
}
