import type { RenderRecord } from '../domain/types.js';
import type { Repository } from './repository.js';

/**
 * Wraps a repository so render lookups come from one preloaded list. The group
 * board advances every participant's look; this turns dozens of queries into one.
 */
export function withRenderCache(repo: Repository, renders: RenderRecord[]): Repository {
  const cache = new Map(renders.map((r) => [r.hash, r]));
  return {
    ...repo,
    async getRender(eventId, hash) {
      const cached = cache.get(hash);
      return cached && cached.eventId === eventId ? structuredClone(cached) : null;
    },
    async insertRenderIfAbsent(render) {
      const inserted = await repo.insertRenderIfAbsent(render);
      if (inserted) cache.set(render.hash, structuredClone(render));
      return inserted;
    },
    async upsertRender(render) {
      await repo.upsertRender(render);
      cache.set(render.hash, structuredClone(render));
    },
    async deleteRender(eventId, hash) {
      await repo.deleteRender(eventId, hash);
      cache.delete(hash);
    },
    async listRenders(eventId) {
      return [...cache.values()].filter((r) => r.eventId === eventId).map((r) => structuredClone(r));
    },
  };
}
