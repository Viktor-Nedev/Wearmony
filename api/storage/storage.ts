/** Private media storage. Every read by a browser goes through short-lived signed URLs. */
export interface MediaStorage {
  put(path: string, bytes: Buffer, contentType: string): Promise<void>;
  get(path: string): Promise<Buffer | null>;
  remove(paths: string[]): Promise<void>;
  /** Removes every object whose path starts with `prefix` (e.g. "events/<id>/"). */
  removePrefix(prefix: string): Promise<void>;
  /** Signed URLs, in the same order as `paths`. May be relative to the API origin. */
  signedUrls(paths: string[], expiresInSeconds: number): Promise<string[]>;
}

export const mediaPaths = {
  eventPrefix: (eventId: string) => `events/${eventId}/`,
  participantPrefix: (eventId: string, userId: string) => `events/${eventId}/people/${userId}/`,
  photo: (eventId: string, userId: string, hash: string) => `events/${eventId}/people/${userId}/photo-${hash.slice(0, 16)}.jpg`,
  render: (eventId: string, userId: string, hash: string) => `events/${eventId}/people/${userId}/render-${hash.slice(0, 16)}.jpg`,
  item: (eventId: string, itemId: string, hash: string) => `events/${eventId}/items/${itemId}-${hash.slice(0, 16)}.jpg`,
};
