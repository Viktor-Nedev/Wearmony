import { createClient } from '@supabase/supabase-js';
import type { MediaStorage } from './storage.js';

/** Private Supabase Storage bucket; browsers only get short-lived signed URLs. */
export function createSupabaseStorage(url: string, secretKey: string, bucket: string): MediaStorage {
  const client = createClient(url, secretKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const store = () => client.storage.from(bucket);

  async function listFiles(folder: string): Promise<string[]> {
    const files: string[] = [];
    for (let offset = 0; ; offset += 1000) {
      const { data, error } = await store().list(folder, { limit: 1000, offset });
      if (error) throw new Error(`Supabase storage list: ${error.message}`);
      for (const entry of data ?? []) {
        const path = folder ? `${folder}/${entry.name}` : entry.name;
        // Folders come back without an id.
        if (entry.id === null) files.push(...(await listFiles(path)));
        else files.push(path);
      }
      if ((data ?? []).length < 1000) return files;
    }
  }

  const storage: MediaStorage = {
    async put(path, bytes, contentType) {
      const { error } = await store().upload(path, bytes, { contentType, upsert: true });
      if (error) throw new Error(`Supabase storage upload: ${error.message}`);
    },
    async get(path) {
      const { data, error } = await store().download(path);
      if (error || !data) return null;
      return Buffer.from(await data.arrayBuffer());
    },
    async remove(paths) {
      for (let i = 0; i < paths.length; i += 1000) {
        const { error } = await store().remove(paths.slice(i, i + 1000));
        if (error) throw new Error(`Supabase storage remove: ${error.message}`);
      }
    },
    async removePrefix(prefix) {
      const folder = prefix.replace(/\/+$/, '');
      await storage.remove(await listFiles(folder));
    },
    async signedUrls(paths, expiresInSeconds) {
      const { data, error } = await store().createSignedUrls(paths, expiresInSeconds);
      if (error) throw new Error(`Supabase storage sign: ${error.message}`);
      const byPath = new Map((data ?? []).map((entry) => [entry.path, entry.signedUrl]));
      return paths.map((path) => byPath.get(path) ?? '');
    },
  };
  return storage;
}
