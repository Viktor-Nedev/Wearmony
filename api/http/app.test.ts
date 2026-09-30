import { describe, expect, it } from 'vitest';
import { ciede2000, hexToLab } from '../harmony/color.js';
import type { TryOnProvider } from '../youcam/provider.js';
import { ANA, BORIS, garmentImage, ORGANIZER, OUTSIDER, portrait, setup } from './test-helpers.js';

const jpeg = { 'Content-Type': 'image/jpeg' };
type Harness = ReturnType<typeof setup>;

async function eventWithTwoParticipants(env: Record<string, string> = {}, overrides = {}) {
  const t = setup(env, overrides);
  const created = await t.call('POST', '/events', ORGANIZER, {
    name: 'Prom 2026',
    template: 'prom',
    budgetPerPerson: 200,
    budgetTotal: 300,
  });
  const eventId: string = created.json.id;
  const code: string = created.json.joinCode;
  await t.call('POST', '/join', ANA, { code, displayName: 'Ana' });
  await t.call('POST', '/join', BORIS, { code: code.toLowerCase(), displayName: 'Boris' });
  return { ...t, eventId, code };
}

async function withPhoto(t: Harness, eventId: string, user: string, pose = 'standing') {
  await t.call('POST', `/events/${eventId}/me/consent`, user);
  return t.call('PUT', `/events/${eventId}/me/photo?pose=${pose}`, user, await portrait(), jpeg);
}

async function addGarment(t: Harness, eventId: string, name: string, color: string, price = 100) {
  const created = await t.call('POST', `/events/${eventId}/items`, ORGANIZER, { type: 'garment', name, price, category: 'full_body' });
  const withImage = await t.call('PUT', `/events/${eventId}/items/${created.json.id}/image`, ORGANIZER, await garmentImage(color), jpeg);
  return withImage.json;
}

async function addColorItem(t: Harness, eventId: string, type: 'makeup' | 'hair', name: string, colorHex: string, price = 20) {
  return (await t.call('POST', `/events/${eventId}/items`, ORGANIZER, { type, name, price, colorHex })).json;
}

describe('health and config', () => {
  it('reports modes without auth', async () => {
    const { call } = setup();
    expect((await call('GET', '/health')).json).toEqual({ ok: true, youcamMode: 'mock', dataMode: 'memory' });
    expect((await call('GET', '/config')).json).toMatchObject({ authMode: 'dev', youcamMode: 'mock', supabaseUrl: null });
  });

  it('requires a valid token for private routes', async () => {
    const { call } = setup();
    expect((await call('GET', '/me/events')).status).toBe(401);
    expect((await call('GET', '/me/events', null, undefined, { Authorization: 'Bearer nonsense' })).status).toBe(401);
  });
});

describe('events', () => {
  it('lets participants join by code and hides the event from outsiders', async () => {
    const t = await eventWithTwoParticipants();
    expect((await t.call('GET', `/join/${t.code}`)).json).toEqual({ name: 'Prom 2026', template: 'prom', demo: false });
    const mine = await t.call('GET', '/me/events', ANA);
    expect(mine.json).toHaveLength(1);
    expect(mine.json[0]).toMatchObject({ isOrganizer: false, isParticipant: true });
    expect((await t.call('GET', `/events/${t.eventId}`, OUTSIDER)).status).toBe(404);
    expect((await t.call('POST', '/join', OUTSIDER, { code: 'ZZZZZZ', displayName: 'X' })).status).toBe(404);
  });

  it('pairs partners both ways', async () => {
    const t = await eventWithTwoParticipants();
    await t.call('PATCH', `/events/${t.eventId}/me`, ANA, { pairWith: BORIS });
    const board = await t.call('GET', `/events/${t.eventId}/board`, ORGANIZER);
    const byName = Object.fromEntries(board.json.participants.map((p: any) => [p.displayName, p]));
    expect(byName.Ana.pairWith).toBe(BORIS);
    expect(byName.Boris.pairWith).toBe(ANA);
  });

  it('only lets the organizer change the event', async () => {
    const t = await eventWithTwoParticipants();
    expect((await t.call('PATCH', `/events/${t.eventId}`, ANA, { name: 'Mine now' })).status).toBe(403);
    const renamed = await t.call('PATCH', `/events/${t.eventId}`, ORGANIZER, { name: 'Prom night', budgetTotal: 500 });
    expect(renamed.json).toMatchObject({ name: 'Prom night', budgetTotal: 500 });
  });
});

describe('photos', () => {
  it('asks for consent and a pose before accepting a photo', async () => {
    const t = await eventWithTwoParticipants();
    const noConsent = await t.call('PUT', `/events/${t.eventId}/me/photo?pose=standing`, ANA, await portrait(), jpeg);
    expect(noConsent.json.error).toBe('consent_required');
    await t.call('POST', `/events/${t.eventId}/me/consent`, ANA);
    const noPose = await t.call('PUT', `/events/${t.eventId}/me/photo`, ANA, await portrait(), jpeg);
    expect(noPose.json.error).toBe('pose_required');
  });

  it('stores a private photo with its quality report', async () => {
    const t = await eventWithTwoParticipants();
    const res = await withPhoto(t, t.eventId, ANA, 'seated');
    expect(res.status).toBe(200);
    expect(res.json).toMatchObject({ hasPhoto: true, pose: 'seated', photoQuality: { issues: [], warnings: [] } });
    const media = await t.app.request(res.json.photoUrl);
    expect(media.status).toBe(200);
    expect(media.headers.get('content-type')).toBe('image/jpeg');
    expect((await t.app.request(res.json.photoUrl.replace(/signature=[^&]+/, 'signature=forged'))).status).toBe(403);
  });

  it('rejects photos that cannot work and files that are not images', async () => {
    const t = await eventWithTwoParticipants();
    await t.call('POST', `/events/${t.eventId}/me/consent`, ANA);
    const small = await t.call('PUT', `/events/${t.eventId}/me/photo?pose=standing`, ANA, await portrait('#6C8EBF', 300, 400), jpeg);
    expect(small.status).toBe(422);
    expect(small.json.details.issues).toContain('too_small');
    const text = await t.call('PUT', `/events/${t.eventId}/me/photo?pose=standing`, ANA, new TextEncoder().encode('hello'), jpeg);
    expect(text.status).toBe(415);
  });
});

describe('catalogue', () => {
  it('extracts garment colors and only lets the organizer edit', async () => {
    const t = await eventWithTwoParticipants();
    const dress = await addGarment(t, t.eventId, 'Red dress', '#B0304A');
    expect(dress.colors[0].share).toBeGreaterThan(0.8);
    expect(ciede2000(hexToLab(dress.colorHex), hexToLab('#B0304A'))).toBeLessThan(3);

    const denied = await t.call('POST', `/events/${t.eventId}/items`, ANA, { type: 'hair', name: 'X', price: 1, colorHex: '#000000' });
    expect(denied.status).toBe(403);
    const lipstick = await addColorItem(t, t.eventId, 'makeup', 'Berry', '#9e2a4b');
    expect(lipstick.colorHex).toBe('#9E2A4B');
    expect((await t.call('GET', `/events/${t.eventId}/items`, ANA)).json).toHaveLength(2);
  });
});

describe('looks and try-on', () => {
  it('renders only when asked, chains apparel then hair, and labels the simulated result', async () => {
    const t = await eventWithTwoParticipants();
    await withPhoto(t, t.eventId, ANA);
    const dress = await addGarment(t, t.eventId, 'Red dress', '#B0304A', 100);
    const hair = await addColorItem(t, t.eventId, 'hair', 'Burgundy', '#5E2230', 60);

    const set = await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: dress.id, hairId: hair.id });
    expect(set.json).toMatchObject({ total: 160, currency: 'EUR', render: { status: 'idle' } });

    const started = await t.call('POST', `/events/${t.eventId}/look/render`, ANA, {});
    expect(started.json.render).toMatchObject({ status: 'running', current: 'apparel', mock: true });
    t.advance(5000);
    expect((await t.call('GET', `/events/${t.eventId}/look`, ANA)).json.render).toMatchObject({ status: 'running', current: 'hair' });
    t.advance(5000);
    const done = (await t.call('GET', `/events/${t.eventId}/look`, ANA)).json.render;
    expect(done).toMatchObject({ status: 'success', mock: true, units: 0, progress: 1 });
    expect(done.checks).toMatchObject({ garmentApplied: true, drift: false });
    expect((await t.app.request(done.resultUrl)).status).toBe(200);
  });

  it('waits for a new request after a change and reuses cached steps', async () => {
    const t = await eventWithTwoParticipants();
    await withPhoto(t, t.eventId, ANA);
    const dress = await addGarment(t, t.eventId, 'Red dress', '#B0304A');
    const burgundy = await addColorItem(t, t.eventId, 'hair', 'Burgundy', '#5E2230');
    const honey = await addColorItem(t, t.eventId, 'hair', 'Honey', '#C8A165');
    const renders = async () => (await t.services.repo.listRenders(t.eventId)).length;

    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: dress.id, hairId: burgundy.id });
    await t.call('POST', `/events/${t.eventId}/look/render`, ANA, {});
    t.advance(5000);
    await t.call('GET', `/events/${t.eventId}/look`, ANA);
    t.advance(5000);
    await t.call('GET', `/events/${t.eventId}/look`, ANA);
    expect(await renders()).toBe(2);

    const changed = await t.call('PUT', `/events/${t.eventId}/look`, ANA, { hairId: honey.id });
    expect(changed.json.render.status).toBe('idle');
    expect(changed.json.render.resultUrl).not.toBeNull();
    expect(await renders()).toBe(2);

    const back = await t.call('PUT', `/events/${t.eventId}/look`, ANA, { hairId: burgundy.id });
    expect(back.json.render.status).toBe('success');
    expect(await renders()).toBe(2);
  });

  it('reports a silent failure and retries a seated participant with upper-body framing', async () => {
    const t = await eventWithTwoParticipants();
    await withPhoto(t, t.eventId, BORIS, 'seated');
    const gown = await addGarment(t, t.eventId, 'mock-fail gown', '#1E7F5C');
    await t.call('PUT', `/events/${t.eventId}/look`, BORIS, { garmentId: gown.id });
    await t.call('POST', `/events/${t.eventId}/look/render`, BORIS, {});
    t.advance(5000);
    expect((await t.call('GET', `/events/${t.eventId}/look`, BORIS)).json.render.status).toBe('running');
    t.advance(5000);
    const failed = (await t.call('GET', `/events/${t.eventId}/look`, BORIS)).json.render;
    expect(failed.status).toBe('failed');
    expect(failed.failure).toMatchObject({ reason: 'garment_not_applied', retryable: false });
    expect(await t.services.repo.listRenders(t.eventId)).toHaveLength(2);
  });

  it('locks a look against changes', async () => {
    const t = await eventWithTwoParticipants();
    const dress = await addGarment(t, t.eventId, 'Red dress', '#B0304A');
    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: dress.id });
    expect((await t.call('POST', `/events/${t.eventId}/look/lock`, ANA, { locked: true })).json.locked).toBe(true);
    expect((await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: null })).status).toBe(423);
    await t.call('POST', `/events/${t.eventId}/look/lock`, ANA, { locked: false });
    expect((await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: null })).status).toBe(200);
  });
});

describe('unit ledger', () => {
  function paidProvider(balance = 100): TryOnProvider {
    let n = 0;
    return {
      mode: 'live',
      typicalDurationMs: 1000,
      cost: () => 2,
      balance: async () => balance,
      start: async () => `task-${n++}`,
      check: async (_id, load) => ({ state: 'success', image: (await load()).image }),
    };
  }

  it('stops paid renders at the participant cap', async () => {
    const t = await eventWithTwoParticipants({ LEDGER_CAP_PER_PARTICIPANT: '2' }, { provider: paidProvider() });
    await withPhoto(t, t.eventId, ANA);
    const first = await addGarment(t, t.eventId, 'Red dress', '#B0304A');
    const second = await addGarment(t, t.eventId, 'Blue dress', '#3A6EA5');

    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: first.id });
    await t.call('POST', `/events/${t.eventId}/look/render`, ANA, {});
    t.advance(9000);
    expect((await t.call('GET', `/events/${t.eventId}/look`, ANA)).json.render).toMatchObject({ status: 'success', units: 2 });

    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: second.id });
    const refused = (await t.call('POST', `/events/${t.eventId}/look/render`, ANA, {})).json.render;
    expect(refused).toMatchObject({ status: 'failed', failure: { reason: 'budget_exhausted' } });
    expect((await t.call('GET', `/events/${t.eventId}/board`, ORGANIZER)).json.units).toMatchObject({ used: 2, mode: 'live' });
  });

  it('keeps the account reserve untouched', async () => {
    const t = await eventWithTwoParticipants({ LEDGER_ACCOUNT_RESERVE: '2' }, { provider: paidProvider(3) });
    await withPhoto(t, t.eventId, ANA);
    const dress = await addGarment(t, t.eventId, 'Red dress', '#B0304A');
    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: dress.id });
    const refused = (await t.call('POST', `/events/${t.eventId}/look/render`, ANA, {})).json.render;
    expect(refused.failure.reason).toBe('budget_exhausted');
  });
});

describe('group board and harmony', () => {
  it('shows everyone with the budget and names the weakest pair', async () => {
    const t = await eventWithTwoParticipants();
    await withPhoto(t, t.eventId, ANA);
    await withPhoto(t, t.eventId, BORIS);
    const blush = await addGarment(t, t.eventId, 'Blush dress', '#E8A0B4', 180);
    const rose = await addGarment(t, t.eventId, 'Rose dress', '#E39AB6', 150);
    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: blush.id });
    await t.call('PUT', `/events/${t.eventId}/look`, BORIS, { garmentId: rose.id });

    const board = (await t.call('GET', `/events/${t.eventId}/board`, ANA)).json;
    expect(board.participantCount).toBe(2);
    expect(board.participants.find((p: any) => p.isMe).displayName).toBe('Ana');
    expect(board.budget).toMatchObject({ total: 330, totalCap: 300, overTotal: true, overBudgetCount: 0 });
    expect(board.harmony.weakest).toMatchObject({ relation: 'near_miss', names: ['Ana', 'Boris'] });
    expect(board.harmony.groupScore).toBeLessThan(60);
    expect((await t.call('GET', `/events/${t.eventId}/harmony`, BORIS)).json.weakest.relation).toBe('near_miss');
  });

  it('explains results with the configured writer, never for scoring', async () => {
    const explainer = { model: 'test-model', explain: async () => 'Ana and Boris wear almost the same pink.' };
    const t = await eventWithTwoParticipants({}, { explainer });
    const blush = await addGarment(t, t.eventId, 'Blush dress', '#E8A0B4');
    const rose = await addGarment(t, t.eventId, 'Rose dress', '#E39AB6');
    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { garmentId: blush.id });
    await t.call('PUT', `/events/${t.eventId}/look`, BORIS, { garmentId: rose.id });
    const res = await t.call('POST', `/events/${t.eventId}/harmony/explain`, ANA, { language: 'en' });
    expect(res.json).toEqual({ text: 'Ana and Boris wear almost the same pink.', model: 'test-model' });
  });
});

describe('vendor links', () => {
  it('shares a read-only hair view that expires', async () => {
    const t = await eventWithTwoParticipants();
    await withPhoto(t, t.eventId, ANA);
    const hair = await addColorItem(t, t.eventId, 'hair', 'Burgundy', '#5E2230');
    await t.call('PUT', `/events/${t.eventId}/look`, ANA, { hairId: hair.id });

    expect((await t.call('POST', `/events/${t.eventId}/vendor-links`, BORIS, { scope: 'hair', userId: ANA })).status).toBe(403);
    const link = await t.call('POST', `/events/${t.eventId}/vendor-links`, ANA, { scope: 'hair', vendorName: 'Salon Iva', hours: 24 });
    expect(link.status).toBe(201);

    const view = await t.call('GET', `/vendor/${link.json.token}`);
    expect(view.json).toMatchObject({ scope: 'hair', participant: { displayName: 'Ana' }, hair: { colorHex: '#5E2230' }, garment: null });
    expect(view.json.photoUrl).toBeTruthy();

    t.advance(25 * 3600_000);
    expect((await t.call('GET', `/vendor/${link.json.token}`)).status).toBe(410);
    expect((await t.call('GET', '/vendor/not-a-token')).status).toBe(404);
  });

  it('lets a catalogue vendor add items without an account', async () => {
    const t = await eventWithTwoParticipants();
    const link = await t.call('POST', `/events/${t.eventId}/vendor-links`, ORGANIZER, { scope: 'catalogue', vendorName: 'Costume room' });
    const item = await t.call('POST', `/vendor/${link.json.token}/items`, null, { type: 'garment', name: 'Velvet cape', price: 0, category: 'outer' });
    expect(item.json).toMatchObject({ vendorName: 'Costume room', name: 'Velvet cape' });
    const image = await t.call('PUT', `/vendor/${link.json.token}/items/${item.json.id}/image`, null, await garmentImage('#6D1F33'), jpeg);
    expect(image.json.colors.length).toBeGreaterThan(0);
    expect((await t.call('GET', `/events/${t.eventId}/items`, ANA)).json).toHaveLength(1);

    const hairLink = await t.call('POST', `/events/${t.eventId}/vendor-links`, ANA, { scope: 'hair' });
    expect((await t.call('POST', `/vendor/${hairLink.json.token}/items`, null, { type: 'hair', name: 'X', price: 1, colorHex: '#000000' })).status).toBe(403);
  });
});

describe('privacy', () => {
  it('lets a participant delete their data and the organizer delete the event', async () => {
    const t = await eventWithTwoParticipants();
    const photo = await withPhoto(t, t.eventId, ANA);
    expect((await t.call('DELETE', `/events/${t.eventId}/me`, ANA)).status).toBe(204);
    expect((await t.call('GET', `/events/${t.eventId}`, ANA)).status).toBe(404);
    expect((await t.app.request(photo.json.photoUrl)).status).toBe(403);

    expect((await t.call('DELETE', `/events/${t.eventId}`, BORIS)).status).toBe(403);
    expect((await t.call('DELETE', `/events/${t.eventId}`, ORGANIZER)).status).toBe(204);
    expect((await t.call('GET', `/events/${t.eventId}`, BORIS)).status).toBe(404);
  });
});

describe('demo event', () => {
  it('seeds an illustrated prom where two partners nearly match', async () => {
    const t = setup();
    const demo = await t.call('POST', '/demo', OUTSIDER);
    expect(demo.json).toMatchObject({ demo: true, isOrganizer: true });

    const board = (await t.call('GET', `/events/${demo.json.id}/board`, OUTSIDER)).json;
    expect(board.participantCount).toBe(6);
    expect(board.renderedCount).toBe(5);
    expect(board.units.mode).toBe('demo');
    expect(board.budget.overBudgetCount).toBe(1);
    expect(board.harmony.weakest).toMatchObject({ relation: 'near_miss', names: ['Maria', 'Ivan'], partners: true });
    expect(board.participants.every((p: any) => p.render.mock)).toBe(true);
  });
});
