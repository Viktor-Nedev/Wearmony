import sharp from 'sharp';

export interface NormalizedImage {
  bytes: Buffer;
  width: number;
  height: number;
}

/**
 * Prepares a photo for an AI provider: applies EXIF rotation, shrinks it to fit
 * `maxLongSide` (never enlarges), fills transparency with white and re-encodes
 * as JPEG. The output carries no metadata, so GPS location and camera details
 * never leave our backend.
 */
export async function normalizeImage(input: Uint8Array, maxLongSide: number, quality = 90): Promise<NormalizedImage> {
  const { data, info } = await sharp(input)
    .rotate()
    .resize({ width: maxLongSide, height: maxLongSide, fit: 'inside', withoutEnlargement: true })
    .flatten({ background: '#ffffff' })
    .jpeg({ quality })
    .toBuffer({ resolveWithObject: true });
  return { bytes: data, width: info.width, height: info.height };
}
