import { z } from 'zod';

// Empty values in .env files ("KEY=") mean "not set", so defaults still apply.
const blankToUndefined = (value: unknown) => (value === '' ? undefined : value);

const optionalString = z.preprocess(blankToUndefined, z.string().optional());
const optionalUrl = z.preprocess(blankToUndefined, z.url().optional());
const number = (fallback: number) =>
  z.preprocess(blankToUndefined, z.coerce.number().nonnegative().default(fallback));
const flag = (fallback: boolean) =>
  z.preprocess(
    blankToUndefined,
    z
      .enum(['true', 'false', '1', '0'])
      .default(fallback ? 'true' : 'false')
      .transform((value) => value === 'true' || value === '1'),
  );

const EnvSchema = z
  .object({
    /** mock: simulated try-on, zero YouCam calls. live: real YouCam API. */
    YOUCAM_MODE: z.preprocess(blankToUndefined, z.enum(['mock', 'live']).default('mock')),
    YOUCAM_API_KEY: optionalString,
    YOUCAM_API_BASE: optionalUrl,
    /** How long a simulated try-on takes in mock mode. */
    MOCK_TRYON_SECONDS: number(4),

    /** memory: everything in process memory (local dev, tests, no-account demo). supabase: Postgres + Storage + Auth. */
    DATA_MODE: z.preprocess(blankToUndefined, z.enum(['memory', 'supabase']).default('memory')),
    SUPABASE_URL: optionalUrl,
    SUPABASE_PUBLISHABLE_KEY: optionalString,
    SUPABASE_SECRET_KEY: optionalString,
    SUPABASE_BUCKET: z.preprocess(blankToUndefined, z.string().default('event-media')),
    /** Accept "dev.<uuid>" tokens. Always on in memory mode; off by default with Supabase. */
    ALLOW_DEV_AUTH: flag(false),

    /** Hard caps in YouCam units. */
    LEDGER_CAP_PER_EVENT: number(40),
    LEDGER_CAP_PER_PARTICIPANT: number(10),
    /** Units to always keep on the account (e.g. for a live demo). */
    LEDGER_ACCOUNT_RESERVE: number(0),

    /** Comma-separated list of allowed browser origins. Unset = localhost only. */
    CORS_ORIGINS: optionalString,

    /** Optional: short plain-language summaries of harmony results. */
    GEMINI_API_KEY: optionalString,
    GEMINI_MODEL: z.preprocess(blankToUndefined, z.string().default('gemini-flash-latest')),
  })
  .superRefine((env, ctx) => {
    if (env.YOUCAM_MODE === 'live' && (!env.YOUCAM_API_KEY || !env.YOUCAM_API_BASE)) {
      ctx.addIssue({ code: 'custom', message: 'YOUCAM_MODE=live requires YOUCAM_API_KEY and YOUCAM_API_BASE' });
    }
    if (env.DATA_MODE === 'supabase' && (!env.SUPABASE_URL || !env.SUPABASE_SECRET_KEY || !env.SUPABASE_PUBLISHABLE_KEY)) {
      ctx.addIssue({
        code: 'custom',
        message: 'DATA_MODE=supabase requires SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY and SUPABASE_SECRET_KEY',
      });
    }
  });

export type Env = z.infer<typeof EnvSchema>;

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  const parsed = EnvSchema.safeParse(source);
  if (!parsed.success) {
    const details = parsed.error.issues.map((issue) => `${issue.path.join('.') || 'env'}: ${issue.message}`).join('; ');
    throw new Error(`Invalid environment: ${details}`);
  }
  return parsed.data;
}
