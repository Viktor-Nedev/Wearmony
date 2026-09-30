import { createHash } from 'node:crypto';
import type { FailureReason, TryOnKind } from '../domain/types.js';
import { normalizeImage } from '../lib/normalize-image.js';
import { YouCamError, type YouCamClient, type YouCamFeature } from './live.js';
import { TryOnStartError, type TryOnProvider, type TryOnResult } from './provider.js';
import {
  APPAREL_FEATURE,
  clothTaskBody,
  hairColorTaskBody,
  lipColorTaskBody,
  TARGET_LONG_SIDE,
  UNIT_COST,
} from './specs.js';

interface FileCache {
  getProviderFile(imageHash: string): Promise<{ fileId: string; uploadedAt: string } | null>;
  putProviderFile(imageHash: string, fileId: string): Promise<void>;
}

/** YouCam keeps file ids for 30 days; re-upload a day early. */
const FILE_ID_TTL_MS = 29 * 24 * 3600 * 1000;

const FEATURE: Record<TryOnKind, YouCamFeature> = {
  apparel: APPAREL_FEATURE,
  makeup: 'makeup-vto',
  hair: 'hair-color',
};

/** Try-on provider backed by the YouCam API. */
export function createLiveProvider(client: YouCamClient, files: FileCache, fetchImpl: typeof fetch = fetch): TryOnProvider {
  async function uploadOnce(bytes: Buffer): Promise<string> {
    const hash = createHash('sha256').update(bytes).digest('hex');
    const cached = await files.getProviderFile(hash);
    if (cached && Date.now() - Date.parse(cached.uploadedAt) < FILE_ID_TTL_MS) return cached.fileId;
    const registered = await client.registerFile({
      contentType: 'image/jpg',
      fileName: `${hash.slice(0, 16)}.jpg`,
      size: bytes.length,
    });
    await client.uploadFile(registered.upload, new Uint8Array(bytes));
    await files.putProviderFile(hash, registered.fileId);
    return registered.fileId;
  }

  return {
    mode: 'live',
    typicalDurationMs: 30_000,
    cost: (kind) => UNIT_COST[FEATURE[kind]],
    async balance() {
      return (await client.getCredit()).total;
    },

    async start(input) {
      const feature = FEATURE[input.kind];
      try {
        const source = (await normalizeImage(input.image, TARGET_LONG_SIDE[feature])).bytes;
        const srcFileId = await uploadOnce(source);
        let body: Record<string, unknown>;
        if (input.kind === 'apparel') {
          if (!input.garment) throw new Error('Apparel try-on needs a garment image');
          const garment = (await normalizeImage(input.garment.image, TARGET_LONG_SIDE[feature])).bytes;
          body = clothTaskBody(srcFileId, await uploadOnce(garment), input.garment.category);
        } else if (input.kind === 'makeup') {
          body = lipColorTaskBody(srcFileId, input.colorHex!);
        } else {
          body = hairColorTaskBody(srcFileId, input.colorHex!);
        }
        const taskId = await client.createTask(feature, body);
        return `${feature}:${taskId}`;
      } catch (error) {
        if (error instanceof YouCamError) {
          const reason: FailureReason =
            error.code === 'CreditInsufficiency' ? 'budget_exhausted' : error.status === 400 ? 'image_invalid' : 'provider_error';
          throw new TryOnStartError(reason, error.code, error.message);
        }
        throw error;
      }
    },

    async check(taskId): Promise<TryOnResult> {
      const separator = taskId.indexOf(':');
      const feature = taskId.slice(0, separator) as YouCamFeature;
      const task = await client.getTask(feature, taskId.slice(separator + 1));
      if (task.state === 'running') return { state: 'running', progress: 0.5 };
      if (task.state === 'error' || !task.resultUrl) {
        return {
          state: 'failed',
          reason: failureReason(task.errorCode),
          code: task.errorCode,
          message: task.errorMessage ?? task.errorCode ?? 'The try-on engine returned an error.',
        };
      }
      const response = await fetchImpl(task.resultUrl);
      if (!response.ok) {
        return { state: 'failed', reason: 'provider_error', code: `download_${response.status}`, message: 'Could not download the result.' };
      }
      const image = (await normalizeImage(Buffer.from(await response.arrayBuffer()), 2048)).bytes;
      return { state: 'success', image };
    },
  };
}

/** Maps YouCam engine error codes (see docs "Error Codes") to reasons the app can explain. */
export function failureReason(code: string | null): FailureReason {
  switch (code) {
    case 'error_pose':
    case 'error_no_shoulder':
    case 'error_invalid_src':
    case 'error_apply_region_mismatch':
      return 'pose_not_supported';
    case 'error_no_face':
    case 'error_face_parsing':
    case 'error_large_face_angle':
    case 'error_face_position_invalid':
    case 'error_face_position_too_small':
    case 'error_face_angle_invalid':
      return 'face_not_found';
    case 'error_editing_failed':
      return 'garment_not_applied';
    case 'error_multi_person':
    case 'error_multiple_people':
      return 'multiple_people';
    case 'exceed_max_filesize':
    case 'error_exceed_max_image_size':
    case 'error_below_min_image_size':
    case 'error_unsupport_ratio':
    case 'error_decode_image':
    case 'error_invalid_ref':
      return 'image_invalid';
    case 'error_nsfw_content_detected':
    case 'exceed_nsfw_retry_limits':
      return 'content_rejected';
    default:
      return 'provider_error';
  }
}
