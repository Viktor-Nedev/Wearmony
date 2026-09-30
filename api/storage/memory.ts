import { createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import type { MediaStorage } from './storage.js';

export interface MemoryStorage extends MediaStorage {
  /** Returns the bytes if the signature is valid and unexpired. Used by GET /api/media. */
  readSigned(path: string, expires: number, signature: string): { bytes: Buffer; contentType: string } | null;
}

/** In-memory media store with HMAC-signed, expiring URLs served by the API itself. */
export function createMemoryStorage(secret: Buffer = randomBytes(32)): MemoryStorage {
  const objects = new Map<string, { bytes: Buffer; contentType: string }>();
  const sign = (path: string, expires: number) =>
    createHmac('sha256', secret).update(`${path}\n${expires}`).digest('base64url');

  return {
    async put(path, bytes, contentType) {
      objects.set(path, { bytes: Buffer.from(bytes), contentType });
    },
    async get(path) {
      const object = objects.get(path);
      return object ? Buffer.from(object.bytes) : null;
    },
    async remove(paths) {
      for (const path of paths) objects.delete(path);
    },
    async removePrefix(prefix) {
      for (const path of objects.keys()) if (path.startsWith(prefix)) objects.delete(path);
    },
    async signedUrls(paths, expiresInSeconds) {
      const expires = Math.floor(Date.now() / 1000) + expiresInSeconds;
      return paths.map(
        (path) => `/api/media?path=${encodeURIComponent(path)}&expires=${expires}&signature=${sign(path, expires)}`,
      );
    },
    readSigned(path, expires, signature) {
      if (!Number.isFinite(expires) || expires < Date.now() / 1000) return null;
      const expected = Buffer.from(sign(path, expires));
      const given = Buffer.from(signature);
      if (expected.length !== given.length || !timingSafeEqual(expected, given)) return null;
      return objects.get(path) ?? null;
    },
  };
}
