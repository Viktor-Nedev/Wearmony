// Wearmony's own vocabulary for try-on. The mapping to YouCam feature slugs,
// endpoints and payloads belongs to the live client in this module only.

export type TryOnKind = 'apparel' | 'makeup' | 'hair';

export type GarmentCategory = 'upper_body' | 'lower_body' | 'full_body' | 'auto';

export interface TryOnRequest {
  kind: TryOnKind;
  /** Storage reference of the participant photo. */
  photoRef: string;
  /** Storage reference of the catalogue item image. */
  itemRef: string;
  garmentCategory?: GarmentCategory;
}

export type TaskState = 'queued' | 'running' | 'success' | 'failed';

export type FailureReason = 'garment_not_applied' | 'provider_error' | 'timeout';

export interface TaskStatus {
  taskId: string;
  state: TaskState;
  /** 0..1, best effort. */
  progress: number;
  resultUrl: string | null;
  failure: { reason: FailureReason; message: string } | null;
  /** True when no real API call was made. The UI must label these results. */
  mock: boolean;
}

export interface TryOnProvider {
  readonly mode: 'mock' | 'live';
  start(request: TryOnRequest): Promise<{ taskId: string }>;
  status(taskId: string): Promise<TaskStatus>;
}

export class UnknownTaskError extends Error {
  constructor(readonly taskId: string) {
    super(`Unknown task: ${taskId}`);
    this.name = 'UnknownTaskError';
  }
}
