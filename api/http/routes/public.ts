import { Hono } from 'hono';
import type { VendorLinkRecord } from '../../domain/types.js';
import { INCLUSION_RESULTS } from '../../generated/inclusion.js';
import { advanceLook } from '../../render/pipeline.js';
import type { Services } from '../../services.js';
import { HttpError, parseJson, readImageBody, type AppEnv } from '../context.js';
import { itemDto, signAll } from '../dto.js';
import { createItem, itemsWithUrls, NewItem, setItemImage } from './catalogue.js';
import { hashToken } from './board.js';
import { itemMap } from './looks.js';

export const publicRoutes = new Hono<AppEnv>();

publicRoutes.get('/health', (c) => {
  const { env, pipeline } = c.var.services;
  return c.json({ ok: true, youcamMode: pipeline.provider.mode, dataMode: env.DATA_MODE });
});

/** Everything the client needs to start: auth mode and public Supabase settings. */
publicRoutes.get('/config', (c) => {
  const { env, auth, pipeline, explainer } = c.var.services;
  return c.json({
    authMode: auth.mode,
    supabaseUrl: auth.mode === 'supabase' ? env.SUPABASE_URL : null,
    // The publishable key is meant for clients; row-level security keeps data private.
    supabasePublishableKey: auth.mode === 'supabase' ? env.SUPABASE_PUBLISHABLE_KEY : null,
    youcamMode: pipeline.provider.mode,
    dataMode: env.DATA_MODE,
    explainAvailable: explainer !== null,
  });
});

publicRoutes.get('/inclusion', (c) => c.json(INCLUSION_RESULTS));

/** Media for memory mode, behind HMAC-signed, expiring URLs. */
publicRoutes.get('/media', (c) => {
  const storage = c.var.services.memoryStorage;
  if (!storage) throw new HttpError(404, 'not_found', 'Not found.');
  const object = storage.readSigned(
    c.req.query('path') ?? '',
    Number(c.req.query('expires')),
    c.req.query('signature') ?? '',
  );
  if (!object) throw new HttpError(403, 'link_expired', 'This media link expired.');
  return c.body(new Uint8Array(object.bytes), 200, {
    'Content-Type': object.contentType,
    'Cache-Control': 'private, max-age=300',
  });
});

async function loadLink(services: Services, token: string): Promise<VendorLinkRecord> {
  const link = await services.repo.getVendorLink(hashToken(token));
  if (!link) throw new HttpError(404, 'link_not_found', 'This link does not exist or was revoked.');
  if (Date.parse(link.expiresAt) < services.now()) throw new HttpError(410, 'link_expired', 'This link has expired.');
  return link;
}

/** Read-only page for a vendor: a hairdresser sees the chosen color and the "before" photo. */
publicRoutes.get('/vendor/:token', async (c) => {
  const services = c.var.services;
  const link = await loadLink(services, c.req.param('token'));
  const event = await services.repo.getEvent(link.eventId);
  if (!event) throw new HttpError(404, 'link_not_found', 'This link does not exist or was revoked.');
  const common = {
    scope: link.scope,
    expiresAt: link.expiresAt,
    vendorName: link.vendorName,
    event: { name: event.name, template: event.template, currency: event.currency, demo: event.demo },
  };

  if (link.scope === 'catalogue') {
    return c.json({ ...common, items: await itemsWithUrls(services, await services.repo.listItems(event.id)) });
  }

  const participant = link.userId ? await services.repo.getParticipant(event.id, link.userId) : null;
  if (!participant) throw new HttpError(404, 'link_not_found', 'The person who shared this look left the event.');
  const look = await services.repo.getLook(event.id, participant.userId);
  const items = await itemMap(services, event.id);
  const state = await advanceLook(services.pipeline, event, participant, look, items);
  const finished = state.status === 'success' && (link.scope === 'look' || state.steps.some((s) => s.kind === 'hair'));
  const pick = (id: string | null | undefined) => (id ? items.get(id) : undefined);
  const [photoUrl, resultUrl, garmentUrl] = await signAll(services.storage, [
    participant.photoPath,
    finished ? state.resultPath : null,
    link.scope === 'look' ? pick(look?.garmentId)?.imagePath : null,
  ]);
  const hair = pick(look?.hairId);
  const garment = pick(look?.garmentId);
  const makeup = pick(look?.makeupId);

  return c.json({
    ...common,
    participant: { displayName: participant.displayName, pose: participant.pose },
    photoUrl,
    resultUrl,
    resultIsSimulated: state.mock,
    hair: hair ? itemDto(hair, null) : null,
    garment: link.scope === 'look' && garment ? itemDto(garment, garmentUrl ?? null) : null,
    makeup: link.scope === 'look' && makeup ? itemDto(makeup, null) : null,
  });
});

/** A costume keeper or shop adds items to the event catalogue through a catalogue link. */
publicRoutes.post('/vendor/:token/items', async (c) => {
  const services = c.var.services;
  const token = c.req.param('token');
  const link = await loadLink(services, token);
  if (link.scope !== 'catalogue') throw new HttpError(403, 'forbidden', 'This link is read-only.');
  const event = await services.repo.getEvent(link.eventId);
  if (!event) throw new HttpError(404, 'link_not_found', 'This link does not exist or was revoked.');
  const item = await createItem(services, event, await parseJson(c, NewItem), vendorTag(token), link.vendorName);
  return c.json(itemDto(item, null), 201);
});

publicRoutes.put('/vendor/:token/items/:itemId/image', async (c) => {
  const services = c.var.services;
  const token = c.req.param('token');
  const link = await loadLink(services, token);
  if (link.scope !== 'catalogue') throw new HttpError(403, 'forbidden', 'This link is read-only.');
  const item = await services.repo.getItem(link.eventId, c.req.param('itemId'));
  // Vendors may only change items they added themselves.
  if (!item || item.addedBy !== vendorTag(token)) throw new HttpError(404, 'item_not_found', 'This item does not exist.');
  const updated = await setItemImage(services, item, await readImageBody(c));
  const [url] = await signAll(services.storage, [updated.imagePath]);
  return c.json(itemDto(updated, url ?? null));
});

const vendorTag = (token: string) => `vendor:${hashToken(token).slice(0, 16)}`;
