import { describe, expect, it } from 'vitest';
import type { RenderRecord } from '../domain/types.js';
import { previewLooks } from './previews.js';

let n = 0;
function step(
  kind: RenderRecord['kind'],
  itemId: string,
  inputPath: string,
  resultPath: string | null,
  status: RenderRecord['status'] = 'success',
  userId = 'me',
): RenderRecord {
  n++;
  const at = new Date(Date.UTC(2026, 9, 3, 10, n)).toISOString();
  return { userId, kind, itemId, inputPath, resultPath, status, updatedAt: at, createdAt: at } as RenderRecord;
}

describe('previewLooks', () => {
  it('turns each finished chain from the photo into one look, newest first', () => {
    const renders = [
      step('apparel', 'navy', 'photo', 'r1'),
      step('makeup', 'berry', 'r1', 'r2'),
      step('apparel', 'blush', 'photo', 'r3'),
      step('hair', 'honey', 'r3', 'r4'),
      step('makeup', 'nude', 'r1', 'r5'),
    ];
    const looks = previewLooks(renders, 'me', 'photo');
    expect(looks).toEqual([
      expect.objectContaining({ garmentId: 'navy', makeupId: 'nude', hairId: null, resultPath: 'r5' }),
      expect.objectContaining({ garmentId: 'blush', makeupId: null, hairId: 'honey', resultPath: 'r4' }),
      expect.objectContaining({ garmentId: 'navy', makeupId: 'berry', hairId: null, resultPath: 'r2' }),
    ]);
  });

  it('ignores failed steps, other people and chains from an old photo', () => {
    const renders = [
      step('apparel', 'navy', 'photo', 'r1'),
      step('makeup', 'berry', 'r1', null, 'failed'),
      step('apparel', 'emerald', 'photo', 'x1', 'success', 'someone else'),
      step('apparel', 'blush', 'old photo', 'r9'),
    ];
    expect(previewLooks(renders, 'me', 'photo')).toEqual([
      expect.objectContaining({ garmentId: 'navy', makeupId: null, resultPath: 'r1' }),
    ]);
  });

  it('has nothing before the first finished preview', () => {
    expect(previewLooks([], 'me', 'photo')).toEqual([]);
  });
});
