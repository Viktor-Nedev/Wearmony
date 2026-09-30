import { createHash } from 'node:crypto';
import type { HarmonyReport } from '../harmony/engine.js';

/** Turns deterministic harmony results into a short friendly note. Never used for scoring. */
export interface Explainer {
  readonly model: string;
  explain(report: HarmonyReport, language: 'en' | 'bg'): Promise<string>;
}

const LANGUAGE = { en: 'English', bg: 'Bulgarian' } as const;

export function buildPrompt(report: HarmonyReport, language: 'en' | 'bg'): string {
  const facts = {
    groupScore: report.groupScore,
    weakest: report.weakest?.sentence ?? null,
    warnings: report.findings.filter((f) => f.relation === 'near_miss').slice(0, 5).map((f) => f.sentence),
    counts: report.counts,
    peopleWithoutOutfit: report.withoutOutfit,
  };
  return [
    'You write a short note for a group of friends choosing outfits for an event together.',
    `Summarize the color-harmony results below in at most three short sentences, in ${LANGUAGE[language]}.`,
    'Use only these facts. Do not invent colors, scores or products. Talk only about colors,',
    'never about bodies, skin, faces or whether something is flattering. Start with the most',
    'important warning, if any, and end with one concrete next step. Plain text, no lists.',
    '',
    `Results: ${JSON.stringify(facts)}`,
  ].join('\n');
}

/** Used when the configured model is overloaded (HTTP 429/5xx), which happens on the free tier. */
const FALLBACK_MODEL = 'gemini-2.5-flash';

export function createGeminiExplainer(apiKey: string, model: string, fetchImpl: typeof fetch = fetch): Explainer {
  const cache = new Map<string, string>();
  const models = model === FALLBACK_MODEL ? [model] : [model, FALLBACK_MODEL];

  async function generate(prompt: string): Promise<Response> {
    let last: Response | null = null;
    for (const candidate of models) {
      last = await fetchImpl(
        `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(candidate)}:generateContent`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
          body: JSON.stringify({
            contents: [{ role: 'user', parts: [{ text: prompt }] }],
            generationConfig: { temperature: 0.3, maxOutputTokens: 2048 },
          }),
        },
      );
      if (last.ok || (last.status !== 429 && last.status < 500)) return last;
    }
    return last!;
  }

  return {
    model,
    async explain(report, language) {
      const prompt = buildPrompt(report, language);
      const key = createHash('sha256').update(`${model}\n${prompt}`).digest('hex');
      const cached = cache.get(key);
      if (cached) return cached;

      const response = await generate(prompt);
      if (!response.ok) throw new Error(`Gemini HTTP ${response.status}: ${(await response.text()).slice(0, 200)}`);
      const json = (await response.json()) as {
        candidates?: { content?: { parts?: { text?: string; thought?: boolean }[] } }[];
      };
      const text = (json.candidates?.[0]?.content?.parts ?? [])
        .filter((part) => !part.thought)
        .map((part) => part.text ?? '')
        .join('')
        .trim();
      if (!text) throw new Error('Gemini returned no text');
      if (cache.size > 200) cache.clear();
      cache.set(key, text);
      return text;
    },
  };
}
