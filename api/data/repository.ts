import type {
  EventRecord,
  ItemRecord,
  LookRecord,
  ParticipantRecord,
  RenderRecord,
  VendorLinkRecord,
} from '../domain/types.js';

/** Persistence for everything except media bytes. Implemented in memory and on Supabase Postgres. */
export interface Repository {
  createEvent(event: EventRecord): Promise<void>;
  getEvent(id: string): Promise<EventRecord | null>;
  getEventByCode(joinCode: string): Promise<EventRecord | null>;
  /** Events the user organizes or participates in, newest first. */
  listEventsForUser(userId: string): Promise<EventRecord[]>;
  updateEvent(
    id: string,
    patch: Partial<Pick<EventRecord, 'name' | 'budgetPerPerson' | 'budgetTotal' | 'eventDate'>>,
  ): Promise<void>;
  /** Deletes the event and every row that belongs to it. */
  deleteEvent(id: string): Promise<void>;

  upsertParticipant(participant: ParticipantRecord): Promise<void>;
  getParticipant(eventId: string, userId: string): Promise<ParticipantRecord | null>;
  listParticipants(eventId: string): Promise<ParticipantRecord[]>;
  /** Deletes the participant with their look and renders. */
  deleteParticipant(eventId: string, userId: string): Promise<void>;

  upsertItem(item: ItemRecord): Promise<void>;
  getItem(eventId: string, itemId: string): Promise<ItemRecord | null>;
  listItems(eventId: string): Promise<ItemRecord[]>;
  deleteItem(eventId: string, itemId: string): Promise<void>;

  upsertLook(look: LookRecord): Promise<void>;
  getLook(eventId: string, userId: string): Promise<LookRecord | null>;
  listLooks(eventId: string): Promise<LookRecord[]>;

  /** Inserts only if no render with this hash exists; returns false if another request got there first. */
  insertRenderIfAbsent(render: RenderRecord): Promise<boolean>;
  upsertRender(render: RenderRecord): Promise<void>;
  getRender(eventId: string, hash: string): Promise<RenderRecord | null>;
  listRenders(eventId: string): Promise<RenderRecord[]>;
  deleteRender(eventId: string, hash: string): Promise<void>;
  deleteRendersForUser(eventId: string, userId: string): Promise<void>;

  createVendorLink(link: VendorLinkRecord): Promise<void>;
  getVendorLink(tokenHash: string): Promise<VendorLinkRecord | null>;
  listVendorLinks(eventId: string): Promise<VendorLinkRecord[]>;
  deleteVendorLink(tokenHash: string): Promise<void>;

  /** YouCam file ids by image content hash (valid for 30 days at YouCam). */
  getProviderFile(imageHash: string): Promise<{ fileId: string; uploadedAt: string } | null>;
  putProviderFile(imageHash: string, fileId: string): Promise<void>;
}
