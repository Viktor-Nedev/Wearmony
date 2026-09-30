import { createClient } from '@supabase/supabase-js';
import type {
  EventRecord,
  ItemRecord,
  LookRecord,
  ParticipantRecord,
  RenderRecord,
  VendorLinkRecord,
} from '../domain/types.js';
import type { Repository } from './repository.js';

// Postgres via PostgREST with the secret key. Every table has row-level security
// switched on with no policies, so only this backend can read or write it.
// Schema: supabase/migrations/.

type Row = Record<string, unknown>;

const eventToRow = (e: EventRecord): Row => ({
  id: e.id,
  name: e.name,
  template: e.template,
  organizer_id: e.organizerId,
  join_code: e.joinCode,
  budget_per_person: e.budgetPerPerson,
  budget_total: e.budgetTotal,
  currency: e.currency,
  demo: e.demo,
  created_at: e.createdAt,
});
const rowToEvent = (r: Row): EventRecord => ({
  id: r.id as string,
  name: r.name as string,
  template: r.template as EventRecord['template'],
  organizerId: r.organizer_id as string,
  joinCode: r.join_code as string,
  budgetPerPerson: toNumberOrNull(r.budget_per_person),
  budgetTotal: toNumberOrNull(r.budget_total),
  currency: r.currency as string,
  demo: r.demo as boolean,
  createdAt: r.created_at as string,
});

const participantToRow = (p: ParticipantRecord): Row => ({
  event_id: p.eventId,
  user_id: p.userId,
  display_name: p.displayName,
  pair_with: p.pairWith,
  photo_path: p.photoPath,
  photo_hash: p.photoHash,
  photo_quality: p.photoQuality,
  pose: p.pose,
  consent_at: p.consentAt,
  joined_at: p.joinedAt,
});
const rowToParticipant = (r: Row): ParticipantRecord => ({
  eventId: r.event_id as string,
  userId: r.user_id as string,
  displayName: r.display_name as string,
  pairWith: (r.pair_with as string | null) ?? null,
  photoPath: (r.photo_path as string | null) ?? null,
  photoHash: (r.photo_hash as string | null) ?? null,
  photoQuality: (r.photo_quality as ParticipantRecord['photoQuality']) ?? null,
  pose: (r.pose as ParticipantRecord['pose']) ?? null,
  consentAt: (r.consent_at as string | null) ?? null,
  joinedAt: r.joined_at as string,
});

const itemToRow = (i: ItemRecord): Row => ({
  id: i.id,
  event_id: i.eventId,
  type: i.type,
  name: i.name,
  price: i.price,
  category: i.category,
  image_path: i.imagePath,
  image_hash: i.imageHash,
  color_hex: i.colorHex,
  dominant_colors: i.dominantColors,
  added_by: i.addedBy,
  vendor_name: i.vendorName,
  created_at: i.createdAt,
});
const rowToItem = (r: Row): ItemRecord => ({
  id: r.id as string,
  eventId: r.event_id as string,
  type: r.type as ItemRecord['type'],
  name: r.name as string,
  price: Number(r.price),
  category: (r.category as ItemRecord['category']) ?? null,
  imagePath: (r.image_path as string | null) ?? null,
  imageHash: (r.image_hash as string | null) ?? null,
  colorHex: (r.color_hex as string | null) ?? null,
  dominantColors: (r.dominant_colors as ItemRecord['dominantColors']) ?? null,
  addedBy: r.added_by as string,
  vendorName: (r.vendor_name as string | null) ?? null,
  createdAt: r.created_at as string,
});

const lookToRow = (l: LookRecord): Row => ({
  event_id: l.eventId,
  user_id: l.userId,
  garment_id: l.garmentId,
  makeup_id: l.makeupId,
  hair_id: l.hairId,
  locked: l.locked,
  render_requested: l.renderRequested,
  updated_at: l.updatedAt,
});
const rowToLook = (r: Row): LookRecord => ({
  eventId: r.event_id as string,
  userId: r.user_id as string,
  garmentId: (r.garment_id as string | null) ?? null,
  makeupId: (r.makeup_id as string | null) ?? null,
  hairId: (r.hair_id as string | null) ?? null,
  locked: r.locked as boolean,
  renderRequested: r.render_requested as boolean,
  updatedAt: r.updated_at as string,
});

const renderToRow = (x: RenderRecord): Row => ({
  event_id: x.eventId,
  hash: x.hash,
  user_id: x.userId,
  kind: x.kind,
  item_id: x.itemId,
  input_path: x.inputPath,
  status: x.status,
  provider_task_id: x.providerTaskId,
  result_path: x.resultPath,
  failure_reason: x.failureReason,
  failure_message: x.failureMessage,
  units: x.units,
  mock: x.mock,
  checks: x.checks,
  checked_at: x.checkedAt,
  created_at: x.createdAt,
  updated_at: x.updatedAt,
});
const rowToRender = (r: Row): RenderRecord => ({
  eventId: r.event_id as string,
  hash: r.hash as string,
  userId: r.user_id as string,
  kind: r.kind as RenderRecord['kind'],
  itemId: r.item_id as string,
  inputPath: r.input_path as string,
  status: r.status as RenderRecord['status'],
  providerTaskId: (r.provider_task_id as string | null) ?? null,
  resultPath: (r.result_path as string | null) ?? null,
  failureReason: (r.failure_reason as RenderRecord['failureReason']) ?? null,
  failureMessage: (r.failure_message as string | null) ?? null,
  units: Number(r.units),
  mock: r.mock as boolean,
  checks: (r.checks as RenderRecord['checks']) ?? null,
  checkedAt: (r.checked_at as string | null) ?? null,
  createdAt: r.created_at as string,
  updatedAt: r.updated_at as string,
});

const linkToRow = (l: VendorLinkRecord): Row => ({
  token_hash: l.tokenHash,
  event_id: l.eventId,
  user_id: l.userId,
  scope: l.scope,
  vendor_name: l.vendorName,
  created_by: l.createdBy,
  expires_at: l.expiresAt,
  created_at: l.createdAt,
});
const rowToLink = (r: Row): VendorLinkRecord => ({
  tokenHash: r.token_hash as string,
  eventId: r.event_id as string,
  userId: (r.user_id as string | null) ?? null,
  scope: r.scope as VendorLinkRecord['scope'],
  vendorName: (r.vendor_name as string | null) ?? null,
  createdBy: r.created_by as string,
  expiresAt: r.expires_at as string,
  createdAt: r.created_at as string,
});

function toNumberOrNull(value: unknown): number | null {
  return value === null || value === undefined ? null : Number(value);
}

interface Result<T> {
  data: T | null;
  error: { message: string; code?: string } | null;
}

function unwrap<T>(result: Result<T>, context: string): T {
  if (result.error) throw new Error(`Supabase ${context}: ${result.error.message}`);
  return result.data as T;
}

export function createSupabaseRepository(url: string, secretKey: string): Repository {
  const db = createClient(url, secretKey, { auth: { persistSession: false, autoRefreshToken: false } });

  return {
    async createEvent(event) {
      unwrap(await db.from('events').insert(eventToRow(event)), 'createEvent');
    },
    async getEvent(id) {
      const row = unwrap(await db.from('events').select('*').eq('id', id).maybeSingle(), 'getEvent');
      return row ? rowToEvent(row) : null;
    },
    async getEventByCode(joinCode) {
      const row = unwrap(await db.from('events').select('*').eq('join_code', joinCode).maybeSingle(), 'getEventByCode');
      return row ? rowToEvent(row) : null;
    },
    async listEventsForUser(userId) {
      const joined = unwrap(await db.from('participants').select('event_id').eq('user_id', userId), 'listEventsForUser');
      const ids = (joined ?? []).map((r: Row) => r.event_id as string);
      const filter = ids.length ? `organizer_id.eq.${userId},id.in.(${ids.join(',')})` : `organizer_id.eq.${userId}`;
      const rows = unwrap(await db.from('events').select('*').or(filter).order('created_at', { ascending: false }), 'listEventsForUser');
      return (rows ?? []).map(rowToEvent);
    },
    async updateEvent(id, patch) {
      const row: Row = {};
      if (patch.name !== undefined) row.name = patch.name;
      if (patch.budgetPerPerson !== undefined) row.budget_per_person = patch.budgetPerPerson;
      if (patch.budgetTotal !== undefined) row.budget_total = patch.budgetTotal;
      if (Object.keys(row).length) unwrap(await db.from('events').update(row).eq('id', id), 'updateEvent');
    },
    async deleteEvent(id) {
      // Participants, items, looks, renders and links cascade.
      unwrap(await db.from('events').delete().eq('id', id), 'deleteEvent');
    },

    async upsertParticipant(participant) {
      unwrap(await db.from('participants').upsert(participantToRow(participant), { onConflict: 'event_id,user_id' }), 'upsertParticipant');
    },
    async getParticipant(eventId, userId) {
      const row = unwrap(
        await db.from('participants').select('*').eq('event_id', eventId).eq('user_id', userId).maybeSingle(),
        'getParticipant',
      );
      return row ? rowToParticipant(row) : null;
    },
    async listParticipants(eventId) {
      const rows = unwrap(await db.from('participants').select('*').eq('event_id', eventId).order('joined_at'), 'listParticipants');
      return (rows ?? []).map(rowToParticipant);
    },
    async deleteParticipant(eventId, userId) {
      // The look, renders and vendor links of this participant cascade.
      unwrap(await db.from('participants').delete().eq('event_id', eventId).eq('user_id', userId), 'deleteParticipant');
    },

    async upsertItem(item) {
      unwrap(await db.from('items').upsert(itemToRow(item), { onConflict: 'id' }), 'upsertItem');
    },
    async getItem(eventId, itemId) {
      const row = unwrap(await db.from('items').select('*').eq('event_id', eventId).eq('id', itemId).maybeSingle(), 'getItem');
      return row ? rowToItem(row) : null;
    },
    async listItems(eventId) {
      const rows = unwrap(await db.from('items').select('*').eq('event_id', eventId).order('created_at'), 'listItems');
      return (rows ?? []).map(rowToItem);
    },
    async deleteItem(eventId, itemId) {
      // Looks that used the item fall back to null (on delete set null).
      unwrap(await db.from('items').delete().eq('event_id', eventId).eq('id', itemId), 'deleteItem');
    },

    async upsertLook(look) {
      unwrap(await db.from('looks').upsert(lookToRow(look), { onConflict: 'event_id,user_id' }), 'upsertLook');
    },
    async getLook(eventId, userId) {
      const row = unwrap(await db.from('looks').select('*').eq('event_id', eventId).eq('user_id', userId).maybeSingle(), 'getLook');
      return row ? rowToLook(row) : null;
    },
    async listLooks(eventId) {
      const rows = unwrap(await db.from('looks').select('*').eq('event_id', eventId), 'listLooks');
      return (rows ?? []).map(rowToLook);
    },

    async insertRenderIfAbsent(render) {
      const { error } = await db.from('renders').insert(renderToRow(render));
      if (!error) return true;
      if (error.code === '23505') return false;
      throw new Error(`Supabase insertRender: ${error.message}`);
    },
    async upsertRender(render) {
      unwrap(await db.from('renders').upsert(renderToRow(render), { onConflict: 'event_id,hash' }), 'upsertRender');
    },
    async getRender(eventId, hash) {
      const row = unwrap(await db.from('renders').select('*').eq('event_id', eventId).eq('hash', hash).maybeSingle(), 'getRender');
      return row ? rowToRender(row) : null;
    },
    async listRenders(eventId) {
      const rows = unwrap(await db.from('renders').select('*').eq('event_id', eventId), 'listRenders');
      return (rows ?? []).map(rowToRender);
    },
    async deleteRender(eventId, hash) {
      unwrap(await db.from('renders').delete().eq('event_id', eventId).eq('hash', hash), 'deleteRender');
    },
    async deleteRendersForUser(eventId, userId) {
      unwrap(await db.from('renders').delete().eq('event_id', eventId).eq('user_id', userId), 'deleteRendersForUser');
    },

    async createVendorLink(link) {
      unwrap(await db.from('vendor_links').insert(linkToRow(link)), 'createVendorLink');
    },
    async getVendorLink(tokenHash) {
      const row = unwrap(await db.from('vendor_links').select('*').eq('token_hash', tokenHash).maybeSingle(), 'getVendorLink');
      return row ? rowToLink(row) : null;
    },
    async listVendorLinks(eventId) {
      const rows = unwrap(await db.from('vendor_links').select('*').eq('event_id', eventId).order('created_at'), 'listVendorLinks');
      return (rows ?? []).map(rowToLink);
    },
    async deleteVendorLink(tokenHash) {
      unwrap(await db.from('vendor_links').delete().eq('token_hash', tokenHash), 'deleteVendorLink');
    },

    async getProviderFile(imageHash) {
      const row = unwrap(
        await db.from('provider_files').select('*').eq('image_hash', imageHash).maybeSingle(),
        'getProviderFile',
      ) as Row | null;
      return row ? { fileId: row.file_id as string, uploadedAt: row.uploaded_at as string } : null;
    },
    async putProviderFile(imageHash, fileId) {
      unwrap(
        await db
          .from('provider_files')
          .upsert({ image_hash: imageHash, file_id: fileId, uploaded_at: new Date().toISOString() }, { onConflict: 'image_hash' }),
        'putProviderFile',
      );
    },
  };
}
