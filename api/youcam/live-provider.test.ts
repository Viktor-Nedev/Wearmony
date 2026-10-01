import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import { createMemoryRepository } from '../data/memory.js';
import { createLiveProvider, failureReason } from './live-provider.js';
import { YouCamError, type YouCamClient } from './live.js';
import { TryOnStartError, type TryOnInput } from './provider.js';

const image = await sharp({ create: { width: 1200, height: 1600, channels: 3, background: '#DADDE2' } }).jpeg().toBuffer();
const garment = await sharp({ create: { width: 400, height: 500, channels: 3, background: '#B0304A' } }).jpeg().toBuffer();

/** Records calls and answers like the real client would. */
function fakeClient(overrides: Partial<YouCamClient> = {}) {
  const calls: string[] = [];
  let files = 0;
  const client: YouCamClient = {
    getCredit: async () => ({ total: 40, entries: [] }),
    getFeatureCosts: async () => [],
    registerFile: async (file) => {
      calls.push(`register ${file.contentType}`);
      return { fileId: `file-${++files}`, upload: { method: 'PUT', url: 'https://s3.example/put', headers: {} } };
    },
    uploadFile: async () => {
      calls.push('upload');
    },
    createTask: async (feature, body) => {
      calls.push(`task ${feature} ${JSON.stringify(body)}`);
      return 'task-1';
    },
    getTask: async () => ({ state: 'success', resultUrl: 'https://s3.example/result.jpg', errorCode: null, errorMessage: null }),
    ...overrides,
  };
  return { client, calls };
}

const apparel: TryOnInput = {
  kind: 'apparel',
  image,
  imageHash: 'photo',
  garment: { image: garment, hash: 'garment', category: 'upper_body', colorHex: '#B0304A' },
};

describe('live try-on provider', () => {
  it('uploads photo and garment once each and creates a cloth-v4 task', async () => {
    const { client, calls } = fakeClient();
    const provider = createLiveProvider(client, createMemoryRepository());

    const taskId = await provider.start(apparel);
    expect(taskId).toBe('cloth-v4:task-1');
    expect(calls.filter((c) => c === 'upload')).toHaveLength(2);
    expect(calls.at(-1)).toContain('"garment_category":"upper_body"');

    await provider.start(apparel);
    // Same images again: the cached file ids are reused, nothing is uploaded twice.
    expect(calls.filter((c) => c === 'upload')).toHaveLength(2);
    expect(provider.cost('apparel')).toBe(2);
    expect(provider.cost('hair')).toBe(1);
  });

  it('sends exact lip and hair colors', async () => {
    const { client, calls } = fakeClient();
    const provider = createLiveProvider(client, createMemoryRepository());
    await provider.start({ kind: 'makeup', image, imageHash: 'p', colorHex: '#9E2A4B' });
    await provider.start({ kind: 'hair', image, imageHash: 'p', colorHex: '#5E2230' });
    expect(calls.find((c) => c.startsWith('task makeup-vto'))).toContain('"color":"#9E2A4B"');
    expect(calls.find((c) => c.startsWith('task hair-color'))).toContain('"color":"#5E2230"');
  });

  it('downloads and normalizes a finished result', async () => {
    const { client } = fakeClient();
    const fetchImpl = (async () => new Response(new Uint8Array(image))) as unknown as typeof fetch;
    const provider = createLiveProvider(client, createMemoryRepository(), fetchImpl);
    const result = await provider.check('cloth-v4:task-1', async () => apparel);
    expect(result.state).toBe('success');
    if (result.state === 'success') expect((await sharp(result.image).metadata()).format).toBe('jpeg');
  });

  it('explains engine errors and refused tasks', async () => {
    const { client } = fakeClient({
      getTask: async () => ({ state: 'error', resultUrl: null, errorCode: 'error_pose', errorMessage: 'Failed to detect pose' }),
      createTask: async () => {
        throw new YouCamError('Insufficient unit', 400, 'CreditInsufficiency');
      },
    });
    const provider = createLiveProvider(client, createMemoryRepository());
    expect(await provider.check('cloth-v4:t', async () => apparel)).toMatchObject({ state: 'failed', reason: 'pose_not_supported' });
    await expect(provider.start(apparel)).rejects.toMatchObject({ reason: 'budget_exhausted' });
    await expect(provider.start(apparel)).rejects.toBeInstanceOf(TryOnStartError);
  });

  it('maps every documented failure family', () => {
    expect(failureReason('error_no_face')).toBe('face_not_found');
    expect(failureReason('error_editing_failed')).toBe('garment_not_applied');
    expect(failureReason('error_multi_person')).toBe('multiple_people');
    expect(failureReason('error_unsupport_ratio')).toBe('image_invalid');
    expect(failureReason('error_nsfw_content_detected')).toBe('content_rejected');
    expect(failureReason('something_new')).toBe('provider_error');
  });
});
