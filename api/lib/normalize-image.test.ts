import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import { normalizeImage } from './normalize-image.js';

const solid = (width: number, height: number) =>
  sharp({ create: { width, height, channels: 3, background: '#884422' } });

describe('normalizeImage', () => {
  it('shrinks a phone-sized photo to the long-side limit', async () => {
    const input = await solid(4032, 3024).jpeg().toBuffer();
    const out = await normalizeImage(input, 1600);
    expect([out.width, out.height]).toEqual([1600, 1200]);
  });

  it('never enlarges small images', async () => {
    const input = await solid(800, 600).png().toBuffer();
    const out = await normalizeImage(input, 1600);
    expect([out.width, out.height]).toEqual([800, 600]);
    expect((await sharp(out.bytes).metadata()).format).toBe('jpeg');
  });

  it('applies EXIF rotation and strips all metadata', async () => {
    const input = await solid(1200, 900).withMetadata({ orientation: 6 }).jpeg().toBuffer();
    const out = await normalizeImage(input, 1600);
    expect([out.width, out.height]).toEqual([900, 1200]);
    const meta = await sharp(out.bytes).metadata();
    expect(meta.exif).toBeUndefined();
    expect(meta.orientation).toBeUndefined();
  });
});
