import { describe, expect, it } from 'vitest';
import { computeHarmony } from '../harmony/engine.js';
import { hexToLab } from '../harmony/color.js';
import { buildPrompt, createGeminiExplainer } from './gemini.js';

const outfit = (hex: string) => [{ hex, lab: [...hexToLab(hex)] as [number, number, number], share: 1 }];
const report = computeHarmony([
  { id: 'a', name: 'Maria', partnerId: 'b', outfit: outfit('#E8A0B4'), lips: null, hair: null },
  { id: 'b', name: 'Ivan', partnerId: 'a', outfit: outfit('#E39AB6'), lips: null, hair: null },
]);

function fakeFetch(responses: { status: number; body: unknown }[]) {
  const urls: string[] = [];
  const impl = (async (url: string | URL | Request) => {
    urls.push(String(url));
    const next = responses.shift()!;
    return new Response(JSON.stringify(next.body), { status: next.status });
  }) as typeof fetch;
  return { impl, urls };
}

const answer = (text: string) => ({ candidates: [{ content: { parts: [{ text: 'thinking', thought: true }, { text }] } }] });

describe('Gemini explainer', () => {
  it('only gives the model the deterministic facts and forbids body talk', () => {
    const prompt = buildPrompt(report, 'bg');
    expect(prompt).toContain('Bulgarian');
    expect(prompt).toContain(report.weakest!.sentence);
    expect(prompt).toMatch(/never about bodies, skin, faces/);
  });

  it('returns the answer text without thoughts and caches it', async () => {
    const fake = fakeFetch([{ status: 200, body: answer('Maria and Ivan nearly match.') }]);
    const explainer = createGeminiExplainer('key', 'gemini-flash-latest', fake.impl);
    expect(await explainer.explain(report, 'en')).toBe('Maria and Ivan nearly match.');
    expect(await explainer.explain(report, 'en')).toBe('Maria and Ivan nearly match.');
    expect(fake.urls).toHaveLength(1);
  });

  it('falls back to a second model when the first is overloaded', async () => {
    const fake = fakeFetch([
      { status: 503, body: { error: { message: 'high demand' } } },
      { status: 200, body: answer('Pick one pink.') },
    ]);
    const explainer = createGeminiExplainer('key', 'gemini-flash-latest', fake.impl);
    expect(await explainer.explain(report, 'en')).toBe('Pick one pink.');
    expect(fake.urls[1]).toContain('gemini-2.5-flash');
  });
});
