// Checks the Supabase setup end to end: schema, cascades, storage and auth settings.
// Creates one test event and deletes it again. Run: npm run check:supabase

import { randomUUID } from 'node:crypto';
import { loadEnv } from '../config/env.js';
import { createSupabaseRepository } from '../data/supabase.js';
import type { RenderRecord } from '../domain/types.js';
import { createSupabaseStorage } from '../storage/supabase.js';

try {
  process.loadEnvFile(new URL('../../.env', import.meta.url));
} catch {
  // Use the process environment.
}

const env = loadEnv({ ...process.env, DATA_MODE: 'supabase' });
const repo = createSupabaseRepository(env.SUPABASE_URL!, env.SUPABASE_SECRET_KEY!);
const storage = createSupabaseStorage(env.SUPABASE_URL!, env.SUPABASE_SECRET_KEY!, env.SUPABASE_BUCKET);

let failures = 0;
async function step(name: string, check: () => Promise<unknown>) {
  try {
    const result = await check();
    if (result === false) throw new Error('unexpected result');
    console.log(`  ok    ${name}`);
  } catch (error) {
    failures++;
    console.log(`  FAIL  ${name}: ${error instanceof Error ? error.message : error}`);
  }
}

const now = new Date().toISOString();
const eventId = randomUUID();
const userId = randomUUID();
const itemId = randomUUID();
const code = `T${randomUUID().replace(/-/g, '').slice(0, 5).toUpperCase()}`;

console.log(`Supabase check against ${env.SUPABASE_URL}`);

await step('create and read an event', async () => {
  await repo.createEvent({
    id: eventId,
    name: 'Setup check',
    template: 'group',
    organizerId: userId,
    joinCode: code,
    budgetPerPerson: 100,
    budgetTotal: null,
    currency: 'EUR',
    eventDate: '2027-05-23',
    dressCode: ['#1F2A44'],
    demo: false,
    createdAt: now,
  });
  const stored = await repo.getEventByCode(code);
  // A missing event_date column (an old schema) shows up here as null.
  return stored?.id === eventId && stored.eventDate === '2027-05-23' && stored.dressCode[0] === '#1F2A44';
});

await step('participant, item and look', async () => {
  await repo.upsertParticipant({
    eventId,
    userId,
    displayName: 'Check',
    pairWith: null,
    photoPath: null,
    photoHash: null,
    photoQuality: null,
    pose: 'seated',
    consentAt: now,
    joinedAt: now,
  });
  await repo.upsertItem({
    id: itemId,
    eventId,
    type: 'hair',
    name: 'Check color',
    price: 10.5,
    category: null,
    imagePath: null,
    imageHash: null,
    colorHex: '#5E2230',
    dominantColors: null,
    addedBy: userId,
    vendorName: null,
    createdAt: now,
  });
  await repo.upsertLook({
    eventId,
    userId,
    garmentId: null,
    makeupId: null,
    hairId: itemId,
    locked: false,
    renderRequested: false,
    updatedAt: now,
  });
  const look = await repo.getLook(eventId, userId);
  const events = await repo.listEventsForUser(userId);
  return look?.hairId === itemId && events.some((e) => e.id === eventId);
});

await step('render cache claims a hash only once', async () => {
  const render: RenderRecord = {
    eventId,
    hash: 'check-hash',
    userId,
    kind: 'hair',
    itemId,
    inputPath: 'x',
    status: 'running',
    providerTaskId: null,
    resultPath: null,
    failureReason: null,
    failureMessage: null,
    units: 1,
    mock: true,
    checks: null,
    checkedAt: now,
    createdAt: now,
    updatedAt: now,
  };
  return (await repo.insertRenderIfAbsent(render)) && !(await repo.insertRenderIfAbsent(render));
});

await step('vendor link', async () => {
  await repo.createVendorLink({
    tokenHash: `check-${eventId}`,
    eventId,
    userId,
    scope: 'hair',
    vendorName: null,
    createdBy: userId,
    expiresAt: now,
    createdAt: now,
  });
  return (await repo.getVendorLink(`check-${eventId}`))?.scope === 'hair';
});

await step('private storage with signed URLs', async () => {
  const path = `events/${eventId}/people/${userId}/check.jpg`;
  await storage.put(path, Buffer.from([0xff, 0xd8, 0xff, 0xd9]), 'image/jpeg');
  const [url] = await storage.signedUrls([path], 60);
  const signed = await fetch(url!);
  const direct = await fetch(`${env.SUPABASE_URL}/storage/v1/object/public/${env.SUPABASE_BUCKET}/${path}`);
  await storage.removePrefix(`events/${eventId}/`);
  const gone = (await storage.get(path)) === null;
  if (!signed.ok) throw new Error(`signed URL returned ${signed.status}`);
  if (direct.ok) throw new Error('the bucket is public; it must be private');
  return gone;
});

await step('deleting the event cascades to everything', async () => {
  await repo.deleteEvent(eventId);
  const leftovers = [
    await repo.getEvent(eventId),
    await repo.getParticipant(eventId, userId),
    await repo.getItem(eventId, itemId),
    await repo.getVendorLink(`check-${eventId}`),
    await repo.getRender(eventId, 'check-hash'),
  ];
  return leftovers.every((value) => value === null);
});

await step('anonymous sign-ins are enabled', async () => {
  const response = await fetch(`${env.SUPABASE_URL}/auth/v1/settings`, { headers: { apikey: env.SUPABASE_PUBLISHABLE_KEY! } });
  const settings = (await response.json()) as { external?: { anonymous_users?: boolean } };
  if (!settings.external?.anonymous_users) {
    throw new Error('turn on Authentication > Sign In / Providers > Allow anonymous sign-ins');
  }
});

console.log(failures ? `\n${failures} check(s) failed.` : '\nSupabase is ready.');
process.exit(failures ? 1 : 0);
