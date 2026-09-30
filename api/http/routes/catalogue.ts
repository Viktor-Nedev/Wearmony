import { createHash, randomUUID } from 'node:crypto';
import { Hono } from 'hono';
import { z } from 'zod';
import type { EventRecord, ItemRecord } from '../../domain/types.js';
import { extractDominantColors } from '../../harmony/extract.js';
import { readImageInfo } from '../../lib/image-size.js';
import { normalizeImage } from '../../lib/normalize-image.js';
import type { Services } from '../../services.js';
import { mediaPaths } from '../../storage/storage.js';
import { HttpError, loadEvent, loadOrganizerEvent, parseJson, readImageBody, requireUser, type AppEnv } from '../context.js';
import { iso, itemDto, signAll } from '../dto.js';

export const catalogue = new Hono<AppEnv>();

const hex = z.string().regex(/^#[0-9a-fA-F]{6}$/).transform((value) => value.toUpperCase());
const name = z.string().trim().min(1).max(80);
const price = z.number().nonnegative().max(100_000).transform((value) => Math.round(value * 100) / 100);
const category = z.enum(['full_body', 'upper_body', 'lower_body', 'outer']);

export const NewItem = z.discriminatedUnion('type', [
  z.object({ type: z.literal('garment'), name, price, category }),
  z.object({ type: z.literal('makeup'), name, price, colorHex: hex }),
  z.object({ type: z.literal('hair'), name, price, colorHex: hex }),
]);

const UpdateItem = z.object({ name: name.optional(), price: price.optional(), category: category.optional(), colorHex: hex.optional() });

export async function createItem(
  services: Services,
  event: EventRecord,
  body: z.infer<typeof NewItem>,
  addedBy: string,
  vendorName: string | null,
): Promise<ItemRecord> {
  const item: ItemRecord = {
    id: randomUUID(),
    eventId: event.id,
    type: body.type,
    name: body.name,
    price: body.price,
    category: body.type === 'garment' ? body.category : null,
    imagePath: null,
    imageHash: null,
    colorHex: body.type === 'garment' ? null : body.colorHex,
    dominantColors: null,
    addedBy,
    vendorName,
    createdAt: iso(services.now()),
  };
  await services.repo.upsertItem(item);
  return item;
}

/** Stores a catalogue image and, for garments, extracts its dominant colors. */
export async function setItemImage(services: Services, item: ItemRecord, raw: Buffer): Promise<ItemRecord> {
  if (!readImageInfo(raw)) throw new HttpError(415, 'unsupported_image', 'Upload a JPG or PNG image.');
  let bytes: Buffer;
  let colors;
  try {
    // Extract from the original so transparent product cut-outs keep their transparency.
    colors = item.type === 'garment' ? await extractDominantColors(raw) : null;
    bytes = (await normalizeImage(raw, 1024)).bytes;
  } catch {
    throw new HttpError(415, 'unsupported_image', 'This image could not be read.');
  }
  if (item.type === 'garment' && (!colors || colors.length === 0)) {
    throw new HttpError(422, 'no_colors', 'No garment colors were found in this image.');
  }

  const hash = createHash('sha256').update(bytes).digest('hex');
  const path = mediaPaths.item(item.eventId, item.id, hash);
  if (item.imagePath) await services.storage.remove([item.imagePath]);
  await services.storage.put(path, bytes, 'image/jpeg');
  const updated: ItemRecord = { ...item, imagePath: path, imageHash: hash, dominantColors: colors ?? item.dominantColors };
  await services.repo.upsertItem(updated);
  return updated;
}

export async function itemsWithUrls(services: Services, items: ItemRecord[]) {
  const urls = await signAll(services.storage, items.map((i) => i.imagePath));
  return items.map((item, i) => itemDto(item, urls[i] ?? null));
}

async function loadItem(services: Services, eventId: string, itemId: string) {
  const item = await services.repo.getItem(eventId, itemId);
  if (!item) throw new HttpError(404, 'item_not_found', 'This item does not exist.');
  return item;
}

catalogue.get('/events/:eventId/items', requireUser, async (c) => {
  const { event } = await loadEvent(c, c.req.param('eventId'));
  return c.json(await itemsWithUrls(c.var.services, await c.var.services.repo.listItems(event.id)));
});

catalogue.post('/events/:eventId/items', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const item = await createItem(c.var.services, event, await parseJson(c, NewItem), c.var.userId, null);
  return c.json(itemDto(item, null), 201);
});

catalogue.put('/events/:eventId/items/:itemId/image', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const item = await loadItem(c.var.services, event.id, c.req.param('itemId'));
  const updated = await setItemImage(c.var.services, item, await readImageBody(c));
  const [url] = await signAll(c.var.services.storage, [updated.imagePath]);
  return c.json(itemDto(updated, url ?? null));
});

catalogue.patch('/events/:eventId/items/:itemId', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const item = await loadItem(c.var.services, event.id, c.req.param('itemId'));
  const body = await parseJson(c, UpdateItem);
  const updated: ItemRecord = {
    ...item,
    name: body.name ?? item.name,
    price: body.price ?? item.price,
    category: item.type === 'garment' ? (body.category ?? item.category) : null,
    colorHex: item.type === 'garment' ? null : (body.colorHex ?? item.colorHex),
  };
  await c.var.services.repo.upsertItem(updated);
  const [url] = await signAll(c.var.services.storage, [updated.imagePath]);
  return c.json(itemDto(updated, url ?? null));
});

catalogue.delete('/events/:eventId/items/:itemId', requireUser, async (c) => {
  const { event } = await loadOrganizerEvent(c, c.req.param('eventId'));
  const item = await loadItem(c.var.services, event.id, c.req.param('itemId'));
  if (item.imagePath) await c.var.services.storage.remove([item.imagePath]);
  await c.var.services.repo.deleteItem(event.id, item.id);
  return c.body(null, 204);
});
