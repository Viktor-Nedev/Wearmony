import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { createYouCamClient, YouCamError } from './live.js';

const fixture = (path: string) =>
  readFileSync(new URL(`../../fixtures/youcam/${path}`, import.meta.url), 'utf8');

interface Call {
  url: string;
  method: string;
  headers: Record<string, string>;
  body: unknown;
}

/** Fake fetch that answers from a queue and records every call. */
function fakeFetch(responses: { status?: number; body: string }[]) {
  const calls: Call[] = [];
  const queue = [...responses];
  const impl = (async (input: string | URL | Request, init?: RequestInit) => {
    calls.push({
      url: String(input),
      method: init?.method ?? 'GET',
      headers: (init?.headers ?? {}) as Record<string, string>,
      body: init?.body,
    });
    const next = queue.shift();
    if (!next) throw new Error('Unexpected request');
    return new Response(next.body, { status: next.status ?? 200 });
  }) as typeof fetch;
  return { impl, calls };
}

function client(responses: { status?: number; body: string }[]) {
  const fake = fakeFetch(responses);
  const youcam = createYouCamClient({
    apiKey: 'test-key',
    baseUrl: 'https://yce-api-01.makeupar.com/',
    fetch: fake.impl,
    sleep: async () => {},
  });
  return { youcam, calls: fake.calls };
}

describe('YouCam client', () => {
  it('reads the unit balance with a bearer token', async () => {
    const { youcam, calls } = client([{ body: fixture('captured/credit.json') }]);
    const credit = await youcam.getCredit();
    expect(credit.total).toBe(40);
    expect(credit.entries[0]?.type).toBe('ApiPaygToken');
    expect(calls[0]?.url).toBe('https://yce-api-01.makeupar.com/s2s/v1.0/client/credit');
    expect(calls[0]?.headers.Authorization).toBe('Bearer test-key');
  });

  it('follows feature-cost pagination and reports try-on prices', async () => {
    const pages = JSON.parse(fixture('captured/feature-cost-pages.json')) as unknown[];
    const { youcam, calls } = client(pages.map((page) => ({ body: JSON.stringify(page) })));
    const costs = await youcam.getFeatureCosts();

    expect(calls).toHaveLength(pages.length);
    expect(calls[1]?.url).toContain('starting_token=');
    const price = (path: string) => costs.filter((c) => c.path === path).map((c) => c.amount);
    expect(price('/s2s/v2.0/task/cloth-v4')).toEqual([2]);
    expect(price('/s2s/v2.0/task/makeup-vto')).toEqual([1]);
    expect(price('/s2s/v2.0/task/hair-color')).toEqual([1, 1]);
  });

  it('registers a file and returns its presigned upload request', async () => {
    const { youcam, calls } = client([{ body: fixture('docs/file-register.json') }]);
    const file = await youcam.registerFile({ contentType: 'image/jpg', fileName: 'p.jpg', size: 547541 });

    expect(calls[0]?.method).toBe('POST');
    expect(calls[0]?.url).toBe('https://yce-api-01.makeupar.com/s2s/v2.0/file');
    expect(JSON.parse(String(calls[0]?.body))).toEqual({
      files: [{ content_type: 'image/jpg', file_name: 'p.jpg', file_size: 547541 }],
    });
    expect(file.fileId).toMatch(/^SaGaqp/);
    expect(file.upload).toMatchObject({
      method: 'PUT',
      headers: { 'Content-Length': '547541', 'Content-Type': 'image/jpg' },
    });
  });

  it('uploads bytes with the presigned method and headers', async () => {
    const { youcam, calls } = client([{ body: '' }]);
    const upload = { method: 'PUT', url: 'https://s3.example/put', headers: { 'Content-Type': 'image/jpg' } };
    await youcam.uploadFile(upload, new Uint8Array([1, 2, 3]));
    expect(calls[0]).toMatchObject({ method: 'PUT', url: 'https://s3.example/put' });
    expect(calls[0]?.headers['Content-Type']).toBe('image/jpg');
  });

  it('creates a cloth task and reads a successful result', async () => {
    const { youcam, calls } = client([
      { body: fixture('docs/task-create.json') },
      { body: fixture('docs/task-status-success.json') },
    ]);
    const taskId = await youcam.createTask('cloth-v4', {
      src_file_id: 'src',
      ref_file_id: 'ref',
      garment_category: 'full_body',
    });
    const task = await youcam.getTask('cloth-v4', taskId);

    expect(calls[0]?.url).toBe('https://yce-api-01.makeupar.com/s2s/v2.0/task/cloth-v4');
    expect(calls[1]?.url).toBe(`https://yce-api-01.makeupar.com/s2s/v2.0/task/cloth-v4/${taskId}`);
    expect(task).toEqual({
      state: 'success',
      resultUrl: expect.stringContaining('s3-accelerate'),
      errorCode: null,
      errorMessage: null,
    });
  });

  it('maps engine errors and in-progress states', async () => {
    const { youcam } = client([
      { body: JSON.stringify({ status: 200, data: { task_status: 'running' } }) },
      {
        body: JSON.stringify({
          status: 200,
          data: { task_status: 'error', error: 'error_pose', error_message: 'Failed to detect pose' },
        }),
      },
    ]);
    expect((await youcam.getTask('cloth-v4', 't')).state).toBe('running');
    expect(await youcam.getTask('cloth-v4', 't')).toMatchObject({ state: 'error', errorCode: 'error_pose' });
  });

  it('turns HTTP errors into YouCamError with the API error code', async () => {
    const { youcam } = client([{ status: 401, body: fixture('docs/error-invalid-key.json') }]);
    await expect(youcam.getCredit()).rejects.toMatchObject({
      name: 'YouCamError',
      status: 401,
      code: 'InvalidAccessToken',
    });
  });

  it('reports insufficient units as a distinct code', async () => {
    const body = JSON.stringify({ status: 400, error: 'Insufficient unit', error_code: 'CreditInsufficiency' });
    const { youcam } = client([{ status: 400, body }]);
    const error = await youcam.createTask('hair-color', { src_file_id: 'x' }).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(YouCamError);
    expect((error as YouCamError).code).toBe('CreditInsufficiency');
  });

  it('retries after HTTP 429 and then succeeds', async () => {
    const { youcam, calls } = client([
      { status: 429, body: JSON.stringify({ status: 429, error: 'Too many requests' }) },
      { body: fixture('captured/credit.json') },
    ]);
    expect((await youcam.getCredit()).total).toBe(40);
    expect(calls).toHaveLength(2);
  });
});
