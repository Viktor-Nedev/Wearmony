import type { PhotoQuality, RenderCheck } from '../harmony/checks.js';
import type { DominantColor } from '../harmony/extract.js';

export type Template = 'prom' | 'theatre' | 'group';
export type Pose = 'standing' | 'seated';
export type ItemType = 'garment' | 'makeup' | 'hair';
export type GarmentCategory = 'full_body' | 'upper_body' | 'lower_body' | 'outer';
export type TryOnKind = 'apparel' | 'makeup' | 'hair';
export type RenderStatus = 'running' | 'success' | 'failed';
export type VendorScope = 'look' | 'hair' | 'catalogue';

export type FailureReason =
  | 'garment_not_applied'
  | 'pose_not_supported'
  | 'face_not_found'
  | 'multiple_people'
  | 'image_invalid'
  | 'content_rejected'
  | 'budget_exhausted'
  | 'provider_error'
  | 'timeout';

export interface EventRecord {
  id: string;
  name: string;
  template: Template;
  organizerId: string;
  joinCode: string;
  /** Optional cap per participant look, in `currency`. */
  budgetPerPerson: number | null;
  /** Optional cap for the whole group, in `currency`. */
  budgetTotal: number | null;
  currency: string;
  /** Seeded demo event: participants and renders are illustrations. */
  demo: boolean;
  createdAt: string;
}

export interface ParticipantRecord {
  eventId: string;
  userId: string;
  displayName: string;
  /** userId of the partner (couples at a prom). */
  pairWith: string | null;
  photoPath: string | null;
  photoHash: string | null;
  photoQuality: PhotoQuality | null;
  pose: Pose | null;
  consentAt: string | null;
  joinedAt: string;
}

export interface ItemRecord {
  id: string;
  eventId: string;
  type: ItemType;
  name: string;
  price: number;
  /** Garments only. */
  category: GarmentCategory | null;
  imagePath: string | null;
  imageHash: string | null;
  /** Makeup (lip color) and hair: the exact color. */
  colorHex: string | null;
  /** Garments: dominant colors from the catalogue image, largest first. */
  dominantColors: DominantColor[] | null;
  addedBy: string;
  vendorName: string | null;
  createdAt: string;
}

export interface LookRecord {
  eventId: string;
  userId: string;
  garmentId: string | null;
  makeupId: string | null;
  hairId: string | null;
  locked: boolean;
  /** Set when the participant presses "Try on"; cleared when the look changes, so no call is ever made unasked. */
  renderRequested: boolean;
  updatedAt: string;
}

export interface RenderRecord {
  eventId: string;
  /** Content hash of input image + item + parameters: the cache key. */
  hash: string;
  userId: string;
  kind: TryOnKind;
  itemId: string;
  inputPath: string;
  status: RenderStatus;
  providerTaskId: string | null;
  resultPath: string | null;
  failureReason: FailureReason | null;
  failureMessage: string | null;
  /** Units reserved for this call (0 in mock mode). */
  units: number;
  mock: boolean;
  checks: RenderCheck | null;
  checkedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface VendorLinkRecord {
  /** SHA-256 of the token; the token itself is never stored. */
  tokenHash: string;
  eventId: string;
  /** Participant whose look is shared (null for catalogue links). */
  userId: string | null;
  scope: VendorScope;
  vendorName: string | null;
  createdBy: string;
  expiresAt: string;
  createdAt: string;
}
