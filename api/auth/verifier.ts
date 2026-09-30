/** Turns a bearer token into a user id. */
export interface AuthVerifier {
  readonly mode: 'dev' | 'supabase';
  verify(token: string): Promise<string | null>;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Local development: the client makes up a UUID and sends "dev.<uuid>". Never enabled with real data unless asked. */
export function createDevVerifier(): AuthVerifier {
  return {
    mode: 'dev',
    async verify(token) {
      const id = token.startsWith('dev.') ? token.slice(4) : '';
      return UUID.test(id) ? id.toLowerCase() : null;
    },
  };
}

/**
 * Supabase Auth: asks the auth server who the token belongs to (so revoked
 * sessions stop working), with a short in-memory cache per token.
 */
export function createSupabaseVerifier(
  url: string,
  apiKey: string,
  options: { fetch?: typeof fetch; now?: () => number; fallback?: AuthVerifier } = {},
): AuthVerifier {
  const doFetch = options.fetch ?? fetch;
  const now = options.now ?? Date.now;
  const cache = new Map<string, { userId: string | null; until: number }>();

  return {
    mode: 'supabase',
    async verify(token) {
      if (options.fallback && token.startsWith('dev.')) return options.fallback.verify(token);
      const cached = cache.get(token);
      if (cached && cached.until > now()) return cached.userId;

      const response = await doFetch(`${url.replace(/\/+$/, '')}/auth/v1/user`, {
        headers: { apikey: apiKey, Authorization: `Bearer ${token}` },
      });
      const userId = response.ok ? (((await response.json()) as { id?: string }).id ?? null) : null;
      if (response.ok || response.status === 401 || response.status === 403) {
        cache.set(token, { userId, until: now() + (userId ? 5 * 60_000 : 30_000) });
      }
      if (cache.size > 5000) cache.clear();
      return userId;
    },
  };
}
