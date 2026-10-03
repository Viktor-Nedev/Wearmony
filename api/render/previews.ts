import type { RenderRecord, TryOnKind } from '../domain/types.js';

// A participant's previous previews, rebuilt from the render records: every
// render chain that starts at their current photo and ends in a finished result
// is one look they have seen (outfit, then lip color, then hair color).

export interface PreviewLook {
  garmentId: string | null;
  makeupId: string | null;
  hairId: string | null;
  /** The last step's image: the look as the participant saw it. */
  resultPath: string;
  /** When that last step finished. */
  at: string;
}

const SLOT: Record<TryOnKind, 'garmentId' | 'makeupId' | 'hairId'> = {
  apparel: 'garmentId',
  makeup: 'makeupId',
  hair: 'hairId',
};

export function previewLooks(renders: RenderRecord[], userId: string, photoPath: string, limit = 8): PreviewLook[] {
  const finished = renders.filter((r) => r.userId === userId && r.status === 'success' && r.resultPath);
  const byInput = new Map<string, RenderRecord[]>();
  for (const render of finished) {
    const list = byInput.get(render.inputPath) ?? [];
    list.push(render);
    byInput.set(render.inputPath, list);
  }

  const looks: PreviewLook[] = [];
  const seen = new Set<string>();
  const walk = (
    path: string,
    look: Omit<PreviewLook, 'resultPath' | 'at'>,
    at: string | null,
    depth: number,
  ) => {
    // Chains are at most three steps; the guard also protects against loops in bad data.
    if (depth > 3 || seen.has(path)) return;
    seen.add(path);
    const next = byInput.get(path) ?? [];
    if (next.length === 0) {
      if (depth > 0 && at) looks.push({ ...look, resultPath: path, at });
      return;
    }
    for (const step of next) {
      walk(step.resultPath!, { ...look, [SLOT[step.kind]]: step.itemId }, step.updatedAt, depth + 1);
    }
  };
  walk(photoPath, { garmentId: null, makeupId: null, hairId: null }, null, 0);

  return looks.sort((a, b) => Date.parse(b.at) - Date.parse(a.at)).slice(0, limit);
}
