import { describe, expect, it } from 'vitest';
import { readImageInfo } from './image-size.js';

function png(width: number, height: number) {
  const bytes = new Uint8Array(33);
  bytes.set([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const view = new DataView(bytes.buffer);
  view.setUint32(8, 13);
  bytes.set([0x49, 0x48, 0x44, 0x52], 12); // IHDR
  view.setUint32(16, width);
  view.setUint32(20, height);
  return bytes;
}

function jpeg(width: number, height: number) {
  return new Uint8Array([
    0xff, 0xd8, // SOI
    0xff, 0xe0, 0x00, 0x06, 0x4a, 0x46, 0x49, 0x46, // APP0, length 6
    0xff, 0xc2, 0x00, 0x0b, 0x08, // SOF2 (progressive), length 11, precision 8
    height >> 8, height & 0xff, width >> 8, width & 0xff,
    0x01, 0x01, 0x11, 0x00,
  ]);
}

describe('readImageInfo', () => {
  it('reads PNG dimensions', () => {
    expect(readImageInfo(png(1024, 768))).toEqual({ format: 'png', width: 1024, height: 768 });
  });

  it('reads JPEG dimensions after other segments', () => {
    expect(readImageInfo(jpeg(3024, 4032))).toEqual({ format: 'jpeg', width: 3024, height: 4032 });
  });

  it('rejects other formats and truncated files', () => {
    expect(readImageInfo(new TextEncoder().encode('GIF89a...'))).toBeNull();
    expect(readImageInfo(new Uint8Array([0xff, 0xd8, 0xff]))).toBeNull();
    expect(readImageInfo(png(10, 10).slice(0, 20))).toBeNull();
  });
});
