import { z } from 'zod';

// Empty values in .env files ("KEY=") mean "not set", so defaults still apply.
const blankToUndefined = (value: unknown) => (value === '' ? undefined : value);

const optionalString = z.preprocess(blankToUndefined, z.string().optional());
const optionalUrl = z.preprocess(blankToUndefined, z.url().optional());
const positiveInt = (fallback: number) =>
  z.preprocess(blankToUndefined, z.coerce.number().int().positive().default(fallback));

const EnvSchema = z
  .object({
    YOUCAM_MODE: z.preprocess(blankToUndefined, z.enum(['mock', 'live']).default('mock')),
    YOUCAM_API_KEY: optionalString,
    YOUCAM_API_BASE: optionalUrl,
    LEDGER_CAP_PER_EVENT: positiveInt(40),
    LEDGER_CAP_PER_PARTICIPANT: positiveInt(10),
    // Comma-separated list of allowed browser origins. Unset = localhost only.
    CORS_ORIGINS: optionalString,
    // How long a simulated try-on takes in mock mode.
    MOCK_TRYON_SECONDS: positiveInt(4),
  })
  .superRefine((env, ctx) => {
    if (env.YOUCAM_MODE === 'live' && (!env.YOUCAM_API_KEY || !env.YOUCAM_API_BASE)) {
      ctx.addIssue({
        code: 'custom',
        message: 'YOUCAM_MODE=live requires YOUCAM_API_KEY and YOUCAM_API_BASE',
      });
    }
  });

export type Env = z.infer<typeof EnvSchema>;

export function loadEnv(source: Record<string, string | undefined> = process.env): Env {
  const parsed = EnvSchema.safeParse(source);
  if (!parsed.success) {
    const details = parsed.error.issues.map((issue) => issue.message).join('; ');
    throw new Error(`Invalid environment: ${details}`);
  }
  return parsed.data;
}
