// Documented YouCam limits and request payloads, in one place.
// Sources: docs.perfectcorp.com reference pages for AI Clothes (V4.0),
// AI Makeup Virtual Try-On (V1.0) and AI Hair Color (V1.0), checked 2026-09-30.

import type { ImageInfo } from '../lib/image-size.js';
import type { YouCamFeature, YouCamGarmentCategory } from './live.js';

const MB = 1024 * 1024;

/** The engine version used for apparel. V2, V3 and V4 all cost 2 units per result. */
export const APPAREL_FEATURE: YouCamFeature = 'cloth-v4';

/** Units per result, from GET /s2s/v2.0/credit/feature-cost (2026-09-30). */
export const UNIT_COST: Record<YouCamFeature, number> = {
  cloth: 2,
  'cloth-v3': 2,
  'cloth-v4': 2,
  'makeup-vto': 1,
  'hair-color': 1,
};

interface ImageLimits {
  minShortSide: number;
  minLongSide: number;
  /** Largest allowed long side, inclusive. */
  maxLongSide: number;
  maxBytes: number;
}

const CLOTH_LIMITS: ImageLimits = { minShortSide: 384, minLongSide: 512, maxLongSide: 4096, maxBytes: 10 * MB };

export const IMAGE_LIMITS: Record<YouCamFeature, ImageLimits> = {
  cloth: CLOTH_LIMITS,
  'cloth-v3': CLOTH_LIMITS,
  'cloth-v4': CLOTH_LIMITS,
  // "long side < 1920, face width >= 100".
  'makeup-vto': { minShortSide: 100, minLongSide: 100, maxLongSide: 1919, maxBytes: 10 * MB },
  // "long side < 1920"; error table: "width >= 320px, height >= 320px".
  'hair-color': { minShortSide: 320, minLongSide: 320, maxLongSide: 1919, maxBytes: 10 * MB },
};

/**
 * Long side we resize photos to before upload: inside the documented limits,
 * large enough for detail, small enough to upload quickly.
 * Hair color is ambiguous in the docs ("long side < 1920" vs an error text
 * saying "height < 1080"); the kill tests check which one holds.
 */
export const TARGET_LONG_SIDE: Record<YouCamFeature, number> = {
  cloth: 2048,
  'cloth-v3': 2048,
  'cloth-v4': 2048,
  'makeup-vto': 1600,
  'hair-color': 1600,
};

/** Returns human-readable problems; an empty list means the image fits the documented limits. */
export function checkImage(feature: YouCamFeature, info: ImageInfo | null, byteLength: number): string[] {
  const limits = IMAGE_LIMITS[feature];
  if (!info) return ['not a JPEG or PNG image'];
  const long = Math.max(info.width, info.height);
  const short = Math.min(info.width, info.height);
  const problems: string[] = [];
  if (byteLength >= limits.maxBytes) problems.push(`file is ${(byteLength / MB).toFixed(1)} MB (limit 10 MB)`);
  if (long > limits.maxLongSide) problems.push(`long side ${long}px exceeds ${limits.maxLongSide}px`);
  if (long < limits.minLongSide || short < limits.minShortSide) {
    problems.push(`${info.width}x${info.height}px is below the minimum ${limits.minLongSide}x${limits.minShortSide}px`);
  }
  return problems;
}

export function clothTaskBody(srcFileId: string, refFileId: string, category: YouCamGarmentCategory) {
  return {
    src_file_id: srcFileId,
    ref_file_id: refFileId,
    garment_category: category,
    // Only the main person is used; bystanders are ignored rather than rejected.
    filter_multi_person: 'off',
  };
}

/** Plain lipstick in one exact color, so the harmony engine knows the lip color precisely. */
export function lipColorTaskBody(srcFileId: string, hex: string) {
  return {
    src_file_id: srcFileId,
    version: '1.0',
    effects: [
      {
        category: 'lip_color',
        shape: { name: 'original' },
        style: { type: 'full' },
        palettes: [{ color: hex, texture: 'satin', colorIntensity: 70 }],
      },
    ],
  };
}

/** Full-coverage hair color in one exact color. */
export function hairColorTaskBody(srcFileId: string, hex: string) {
  return {
    src_file_id: srcFileId,
    pattern: { name: 'full' },
    palettes: [{ color: hex, color_intensity: 80 }],
  };
}
