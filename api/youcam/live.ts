// HTTP client for the YouCam API (docs.perfectcorp.com). This is the only file
// that knows YouCam paths, payloads and response shapes.
//
// Flow: register file -> PUT bytes to the presigned URL -> create task -> poll.
// Notes from the official docs:
// - Auth header: "Authorization: Bearer <key>".
// - Rate limit: 250 requests per 300 s per IP and per key (HTTP 429).
// - file_id and task_id stay valid for 30 days, result URLs for 2 hours.
// - Some numeric ids exceed 2^53; we never read them, so plain JSON.parse is fine.

export type YouCamFeature = 'cloth' | 'cloth-v3' | 'cloth-v4' | 'makeup-vto' | 'hair-color';

export type YouCamGarmentCategory =
  | 'full_body'
  | 'upper_body'
  | 'lower_body'
  | 'shoes'
  | 'outer'
  | 'auto';

export interface UploadRequest {
  method: string;
  url: string;
  headers: Record<string, string>;
}

export interface RegisteredFile {
  fileId: string;
  upload: UploadRequest;
}

export interface CreditBalance {
  total: number;
  entries: { type: string; amount: number; expiresAt: number }[];
}

export interface FeatureCost {
  description: string;
  amount: number;
  unit: string;
  path: string;
}

export interface YouCamTask {
  state: 'running' | 'success' | 'error';
  resultUrl: string | null;
  errorCode: string | null;
  errorMessage: string | null;
}

export class YouCamError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code: string | null,
  ) {
    super(message);
    this.name = 'YouCamError';
  }
}

interface ClientOptions {
  apiKey: string;
  baseUrl: string;
  fetch?: typeof fetch;
  sleep?: (ms: number) => Promise<void>;
  /** Attempts for requests rejected with HTTP 429. */
  maxAttempts?: number;
}

const defaultSleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

export function createYouCamClient(options: ClientOptions) {
  const doFetch = options.fetch ?? fetch;
  const sleep = options.sleep ?? defaultSleep;
  const maxAttempts = options.maxAttempts ?? 3;
  const base = options.baseUrl.replace(/\/+$/, '');

  async function request<T>(method: 'GET' | 'POST', path: string, body?: unknown): Promise<T> {
    for (let attempt = 1; ; attempt++) {
      const response = await doFetch(`${base}${path}`, {
        method,
        headers: {
          Authorization: `Bearer ${options.apiKey}`,
          ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      if (response.status === 429 && attempt < maxAttempts) {
        await sleep(2000 * attempt);
        continue;
      }
      const text = await response.text();
      const json = parseJson(text);
      if (!response.ok) {
        const error = typeof json?.error === 'string' ? json.error : text.slice(0, 200);
        const code = typeof json?.error_code === 'string' ? json.error_code : null;
        throw new YouCamError(`${method} ${path} failed: ${error}`, response.status, code);
      }
      return json as T;
    }
  }

  return {
    async getCredit(): Promise<CreditBalance> {
      const json = await request<{ results?: CreditEntry[] }>('GET', '/s2s/v1.0/client/credit');
      const entries = (json.results ?? []).map((entry) => ({
        type: entry.type,
        amount: entry.amount_dec ?? entry.amount ?? 0,
        expiresAt: entry.expiry,
      }));
      return { total: round2(entries.reduce((sum, entry) => sum + entry.amount, 0)), entries };
    },

    async getFeatureCosts(): Promise<FeatureCost[]> {
      const costs: FeatureCost[] = [];
      let token: string | null = null;
      do {
        const query: string = `?page_size=20${token ? `&starting_token=${encodeURIComponent(token)}` : ''}`;
        const json = await request<FeatureCostPage>('GET', `/s2s/v2.0/credit/feature-cost${query}`);
        for (const sku of json.result?.skus ?? []) {
          costs.push({
            description: sku.description,
            amount: sku.amount,
            unit: sku.unit,
            path: new URL(sku.run_task_url).pathname,
          });
        }
        token = json.result?.next_token ?? null;
      } while (token);
      return costs;
    },

    async registerFile(file: { contentType: string; fileName: string; size: number }): Promise<RegisteredFile> {
      const json = await request<FileResponse>('POST', '/s2s/v2.0/file', {
        files: [{ content_type: file.contentType, file_name: file.fileName, file_size: file.size }],
      });
      const entry = json.data?.files?.[0];
      const upload = entry?.requests?.[0];
      if (!entry?.file_id || !upload?.url) {
        throw new YouCamError('File API response has no file_id or upload URL', 200, null);
      }
      return {
        fileId: entry.file_id,
        upload: { method: upload.method ?? 'PUT', url: upload.url, headers: stringifyValues(upload.headers ?? {}) },
      };
    },

    async uploadFile(upload: UploadRequest, bytes: Uint8Array<ArrayBuffer>): Promise<void> {
      const response = await doFetch(upload.url, {
        method: upload.method,
        headers: upload.headers,
        body: bytes,
      });
      if (!response.ok) {
        throw new YouCamError(`Upload failed with HTTP ${response.status}`, response.status, null);
      }
    },

    async createTask(feature: YouCamFeature, body: Record<string, unknown>): Promise<string> {
      const json = await request<{ data?: { task_id?: string } }>('POST', `/s2s/v2.0/task/${feature}`, body);
      const taskId = json.data?.task_id;
      if (!taskId) throw new YouCamError('Task response has no task_id', 200, null);
      return taskId;
    },

    async getTask(feature: YouCamFeature, taskId: string): Promise<YouCamTask> {
      const json = await request<TaskResponse>(
        'GET',
        `/s2s/v2.0/task/${feature}/${encodeURIComponent(taskId)}`,
      );
      const data = json.data ?? {};
      const state = data.task_status === 'success' ? 'success' : data.task_status === 'error' ? 'error' : 'running';
      return {
        state,
        resultUrl: data.results?.url ?? null,
        errorCode: data.error ?? null,
        errorMessage: data.error_message ?? null,
      };
    },
  };
}

export type YouCamClient = ReturnType<typeof createYouCamClient>;

interface CreditEntry {
  type: string;
  amount?: number;
  amount_dec?: number;
  expiry: number;
}

interface FeatureCostPage {
  result?: {
    next_token?: string | null;
    skus?: { description: string; amount: number; unit: string; run_task_url: string }[];
  };
}

interface FileResponse {
  data?: {
    files?: {
      file_id?: string;
      requests?: { method?: string; url?: string; headers?: Record<string, unknown> }[];
    }[];
  };
}

interface TaskResponse {
  data?: {
    task_status?: string;
    error?: string | null;
    error_message?: string | null;
    results?: { url?: string } | null;
  };
}

function parseJson(text: string): Record<string, unknown> | null {
  try {
    return JSON.parse(text) as Record<string, unknown>;
  } catch {
    return null;
  }
}

function stringifyValues(headers: Record<string, unknown>): Record<string, string> {
  return Object.fromEntries(Object.entries(headers).map(([key, value]) => [key, String(value)]));
}

function round2(value: number) {
  return Math.round(value * 100) / 100;
}
