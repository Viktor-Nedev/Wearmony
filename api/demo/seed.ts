import { createHash, randomUUID } from 'node:crypto';
import sharp from 'sharp';
import type {
  EventRecord,
  GarmentCategory,
  ItemRecord,
  LookRecord,
  ParticipantRecord,
  Pose,
  RenderRecord,
  Template,
} from '../domain/types.js';
import { checkPhotoQuality } from '../harmony/checks.js';
import { extractDominantColors } from '../harmony/extract.js';
import { apparelCategories, planSteps, stepHash } from '../render/pipeline.js';
import type { Services } from '../services.js';
import { mediaPaths } from '../storage/storage.js';

// Seeded events with fictional, illustrated participants: a prom, and a school
// theatre cast to show the same engine on another kind of event. Every image is
// a drawing, and the app labels the event and its renders as demo data.

type Shape = 'dress' | 'gown' | 'suit' | 'tie' | 'blazer';

interface DemoItem {
  key: string;
  type: 'garment' | 'makeup' | 'hair';
  name: string;
  price: number;
  color: string;
  category?: GarmentCategory;
  shape?: Shape;
}

const PROM_ITEMS: DemoItem[] = [
  { key: 'blush', type: 'garment', name: 'Blush satin dress', price: 180, color: '#E8A0B4', category: 'full_body', shape: 'dress' },
  { key: 'roseTie', type: 'garment', name: 'Rose tie and pocket square', price: 35, color: '#E39AB6', category: 'upper_body', shape: 'tie' },
  { key: 'blushTie', type: 'garment', name: 'Blush tie and pocket square', price: 35, color: '#E8A0B4', category: 'upper_body', shape: 'tie' },
  // Next to the champagne dress the sand tie is a near-miss (ΔE about 7.7 after extraction); the champagne tie matches.
  { key: 'sandTie', type: 'garment', name: 'Sand tie and pocket square', price: 35, color: '#D7BD90', category: 'upper_body', shape: 'tie' },
  { key: 'champagneTie', type: 'garment', name: 'Champagne tie and pocket square', price: 35, color: '#E9D8B8', category: 'upper_body', shape: 'tie' },
  { key: 'navy', type: 'garment', name: 'Navy suit', price: 260, color: '#1F2A44', category: 'full_body', shape: 'suit' },
  { key: 'emerald', type: 'garment', name: 'Emerald gown', price: 210, color: '#1E7F5C', category: 'full_body', shape: 'gown' },
  { key: 'champagne', type: 'garment', name: 'Champagne dress', price: 195, color: '#E9D8B8', category: 'full_body', shape: 'dress' },
  { key: 'blazer', type: 'garment', name: 'Burgundy velvet blazer', price: 150, color: '#6D1F33', category: 'outer', shape: 'blazer' },
  { key: 'berry', type: 'makeup', name: 'Berry lipstick', price: 18, color: '#9E2A4B' },
  { key: 'nude', type: 'makeup', name: 'Nude rose lipstick', price: 15, color: '#C98A7D' },
  { key: 'honey', type: 'hair', name: 'Honey blonde', price: 60, color: '#C8A165' },
  { key: 'burgundyHair', type: 'hair', name: 'Deep burgundy', price: 70, color: '#5E2230' },
];

interface DemoPerson {
  key: string;
  name: string;
  pose: Pose;
  skin: string;
  hair: string;
  partner: string | null;
  look: { garment: string; makeup?: string; hair?: string };
}

/** The person opening the demo. Their avatar is an illustration and they have not consented to anything yet. */
const VISITOR = 'visitor';

const PROM_PEOPLE: DemoPerson[] = [
  { key: 'maria', name: 'Maria', pose: 'standing', skin: '#E8B998', hair: '#4A3222', partner: 'ivan', look: { garment: 'blush', makeup: 'berry', hair: 'honey' } },
  { key: 'ivan', name: 'Ivan', pose: 'standing', skin: '#F1CDB0', hair: '#2B211B', partner: 'maria', look: { garment: 'blushTie' } },
  { key: 'elena', name: 'Elena', pose: 'seated', skin: '#8D5A3B', hair: '#1E1612', partner: 'georgi', look: { garment: 'emerald', makeup: 'nude' } },
  { key: 'georgi', name: 'Georgi', pose: 'standing', skin: '#C68E6A', hair: '#3A2A20', partner: 'elena', look: { garment: 'navy' } },
  { key: 'sofia', name: 'Sofia', pose: 'standing', skin: '#B07A55', hair: '#6B4A2E', partner: VISITOR, look: { garment: 'champagne', hair: 'burgundyHair' } },
];

// Romeo's and Mercutio's doublets are two teals that nearly match: on stage that
// reads as a costume mistake. Mercutio is played from a wheelchair.
const THEATRE_ITEMS: DemoItem[] = [
  { key: 'ivoryGown', type: 'garment', name: "Juliet's ivory gown", price: 95, color: '#EFE6D2', category: 'full_body', shape: 'gown' },
  { key: 'romeoTeal', type: 'garment', name: "Romeo's teal doublet", price: 70, color: '#1F6F78', category: 'outer', shape: 'blazer' },
  { key: 'mercutioTeal', type: 'garment', name: "Mercutio's teal doublet", price: 70, color: '#2A7F86', category: 'outer', shape: 'blazer' },
  { key: 'mustard', type: 'garment', name: 'Mustard doublet', price: 65, color: '#C99A2E', category: 'outer', shape: 'blazer' },
  { key: 'crimson', type: 'garment', name: "Tybalt's crimson doublet", price: 75, color: '#8E1B2A', category: 'outer', shape: 'blazer' },
  { key: 'sand', type: 'garment', name: "Nurse's sand dress", price: 60, color: '#C9B08A', category: 'full_body', shape: 'dress' },
  { key: 'robe', type: 'garment', name: "Friar's brown robe", price: 55, color: '#6B4E31', category: 'full_body', shape: 'gown' },
  { key: 'stageRed', type: 'makeup', name: 'Stage red lipstick', price: 12, color: '#A3243B' },
  { key: 'auburn', type: 'hair', name: 'Auburn wig', price: 45, color: '#8B3A1E' },
  { key: 'raven', type: 'hair', name: 'Raven wig', price: 45, color: '#1B1B1F' },
];

const THEATRE_PEOPLE: DemoPerson[] = [
  { key: 'juliet', name: 'Juliet', pose: 'standing', skin: '#F0C9A8', hair: '#5A3A22', partner: 'romeo', look: { garment: 'ivoryGown', makeup: 'stageRed', hair: 'auburn' } },
  { key: 'romeo', name: 'Romeo', pose: 'standing', skin: '#C68E6A', hair: '#2B211B', partner: 'juliet', look: { garment: 'romeoTeal' } },
  { key: 'mercutio', name: 'Mercutio', pose: 'seated', skin: '#8D5A3B', hair: '#1E1612', partner: null, look: { garment: 'mercutioTeal' } },
  { key: 'tybalt', name: 'Tybalt', pose: 'standing', skin: '#E8B998', hair: '#3A2A20', partner: null, look: { garment: 'crimson', hair: 'raven' } },
  { key: 'nurse', name: 'Nurse', pose: 'standing', skin: '#B07A55', hair: '#6B6460', partner: null, look: { garment: 'sand' } },
];

// The visitor arrives as Sofia's partner in the sand tie, so the near-miss and its
// one-tap fix are theirs to try right away.
const PROM_VISITOR: DemoPerson = {
  key: VISITOR,
  name: 'Guest',
  pose: 'standing',
  skin: '#D9A77F',
  hair: '#2B211B',
  partner: 'sofia',
  look: { garment: 'sandTie' },
};

export type DemoKind = 'prom' | 'theatre';

interface Scenario {
  name: string;
  template: Template;
  budgetPerPerson: number;
  budgetTotal: number;
  /** Month (1-12) and day of the event: the next one from today. */
  day: [number, number];
  items: DemoItem[];
  people: DemoPerson[];
  /** Whose look is already locked, to show a finished look. */
  locked: string;
  /** Who added the hair items, as shown in the catalogue. */
  hairVendor: string;
  /** The visitor's illustrated avatar and look; without one they join with no photo. */
  visitor?: DemoPerson;
}

const SCENARIOS: Record<DemoKind, Scenario> = {
  // Bulgarian proms are in late May.
  prom: {
    name: 'Class of 2027 prom (demo)',
    template: 'prom',
    budgetPerPerson: 260,
    budgetTotal: 1200,
    day: [5, 23],
    items: PROM_ITEMS,
    people: PROM_PEOPLE,
    locked: 'georgi',
    hairVendor: 'Salon demo',
    visitor: PROM_VISITOR,
  },
  // World Theatre Day.
  theatre: {
    name: 'Romeo and Juliet: school cast (demo)',
    template: 'theatre',
    budgetPerPerson: 120,
    budgetTotal: 600,
    day: [3, 27],
    items: THEATRE_ITEMS,
    people: THEATRE_PEOPLE,
    locked: 'nurse',
    hairVendor: 'Wig room demo',
  },
};

const BEFORE_CLOTHING = '#9FB3C8';

/** The next given month (1-12) and day from today, as YYYY-MM-DD. */
export function nextDay(now: number, month: number, day: number): string {
  const today = new Date(now);
  let year = today.getUTCFullYear();
  if (Date.UTC(year, month - 1, day) < Date.UTC(year, today.getUTCMonth(), today.getUTCDate())) year++;
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

export async function seedDemoEvent(
  services: Services,
  organizerId: string,
  kind: DemoKind = 'prom',
): Promise<EventRecord> {
  const { repo, storage } = services;
  const scenario = SCENARIOS[kind];
  const ITEMS = scenario.items;
  const PEOPLE = scenario.people;
  let clock = services.now();
  const stamp = () => new Date(clock++).toISOString();

  const event: EventRecord = {
    id: randomUUID(),
    name: scenario.name,
    template: scenario.template,
    organizerId,
    joinCode: `D${randomUUID().replace(/-/g, '').slice(0, 5).toUpperCase()}`,
    budgetPerPerson: scenario.budgetPerPerson,
    budgetTotal: scenario.budgetTotal,
    currency: 'EUR',
    eventDate: nextDay(services.now(), ...scenario.day),
    demo: true,
    createdAt: stamp(),
  };
  await repo.createEvent(event);

  const items = new Map<string, ItemRecord>();
  for (const spec of ITEMS) {
    const item: ItemRecord = {
      id: randomUUID(),
      eventId: event.id,
      type: spec.type,
      name: spec.name,
      price: spec.price,
      category: spec.category ?? null,
      imagePath: null,
      imageHash: null,
      colorHex: spec.type === 'garment' ? null : spec.color,
      dominantColors: null,
      addedBy: organizerId,
      vendorName: spec.type === 'hair' ? scenario.hairVendor : null,
      createdAt: stamp(),
    };
    if (spec.shape) {
      const image = await toJpeg(garmentSvg(spec.shape, spec.color), 400, 500);
      const hash = sha256(image);
      item.imagePath = mediaPaths.item(event.id, item.id, hash);
      item.imageHash = hash;
      item.dominantColors = await extractDominantColors(image);
      await storage.put(item.imagePath, image, 'image/jpeg');
    }
    await repo.upsertItem(item);
    items.set(spec.key, item);
  }
  const byId = new Map([...items.values()].map((item) => [item.id, item]));

  const cast = scenario.visitor ? [...PEOPLE, scenario.visitor] : PEOPLE;
  const ids = new Map(cast.map((p) => [p.key, p.key === VISITOR ? organizerId : randomUUID()]));
  for (const person of cast) {
    const userId = ids.get(person.key)!;
    const isVisitor = person.key === VISITOR;
    const before = await toJpeg(personSvg(person, { clothing: BEFORE_CLOTHING }), 600, 900);
    const photoHash = sha256(before);
    const photoPath = mediaPaths.photo(event.id, userId, photoHash);
    await storage.put(photoPath, before, 'image/jpeg');

    const participant: ParticipantRecord = {
      eventId: event.id,
      userId,
      displayName: person.name,
      pairWith: person.partner ? ids.get(person.partner)! : null,
      photoPath,
      photoHash,
      photoQuality: await checkPhotoQuality(before),
      pose: person.pose,
      // A real photo needs the visitor's explicit consent first, so it stays unset.
      consentAt: isVisitor ? null : stamp(),
      joinedAt: stamp(),
    };
    await repo.upsertParticipant(participant);

    const look: LookRecord = {
      eventId: event.id,
      userId,
      garmentId: items.get(person.look.garment)!.id,
      makeupId: person.look.makeup ? items.get(person.look.makeup)!.id : null,
      hairId: person.look.hair ? items.get(person.look.hair)!.id : null,
      locked: person.key === scenario.locked,
      renderRequested: true,
      updatedAt: stamp(),
    };
    await repo.upsertLook(look);

    // Precomputed illustrations for each step of the look, stored exactly where
    // the render pipeline looks for them.
    let inputHash = photoHash;
    let inputPath = photoPath;
    const drawn: Drawn = { clothing: BEFORE_CLOTHING, hair: person.hair, lips: null, tie: null };
    for (const step of planSteps(look, byId)) {
      const category = step.kind === 'apparel' ? apparelCategories(participant, step.item)[0]! : null;
      if (step.kind === 'apparel') {
        const color = step.item.dominantColors?.[0]?.hex ?? drawn.clothing;
        const isTie = ITEMS.find((spec) => items.get(spec.key)?.id === step.item.id)?.shape === 'tie';
        drawn.clothing = isTie ? '#F4F4F4' : color;
        drawn.tie = isTie ? color : null;
      }
      if (step.kind === 'makeup') drawn.lips = step.item.colorHex;
      if (step.kind === 'hair') drawn.hair = step.item.colorHex ?? drawn.hair;

      const hash = stepHash(inputHash, step, category, 'demo');
      const resultPath = mediaPaths.render(event.id, userId, hash);
      await storage.put(resultPath, await toJpeg(personSvg(person, drawn), 600, 900), 'image/jpeg');
      const time = stamp();
      const render: RenderRecord = {
        eventId: event.id,
        hash,
        userId,
        kind: step.kind,
        itemId: step.item.id,
        inputPath,
        status: 'success',
        providerTaskId: 'demo',
        resultPath,
        failureReason: null,
        failureMessage: null,
        units: 0,
        mock: true,
        checks: null,
        checkedAt: time,
        createdAt: time,
        updatedAt: time,
      };
      await repo.upsertRender(render);
      inputHash = hash;
      inputPath = resultPath;
    }
  }

  // Without a prepared avatar the visitor joins with no photo, to try the participant flow.
  if (!scenario.visitor) {
    await repo.upsertParticipant({
      eventId: event.id,
      userId: organizerId,
      displayName: 'Guest',
      pairWith: null,
      photoPath: null,
      photoHash: null,
      photoQuality: null,
      pose: null,
      consentAt: null,
      joinedAt: stamp(),
    });
  }
  return event;
}

interface Drawn {
  clothing: string;
  hair?: string;
  lips?: string | null;
  tie?: string | null;
}

function personSvg(person: DemoPerson, look: Drawn): string {
  const hair = look.hair ?? person.hair;
  const lips = look.lips ?? '#B9786E';
  const tie = look.tie
    ? `<path d="M290 276 L310 276 L318 300 L313 470 L300 492 L287 470 L282 300 Z" fill="${look.tie}"/>`
    : '';
  const head = `
    <path d="M222 180 Q222 88 300 84 Q378 88 378 180 L378 250 Q350 205 300 204 Q250 205 222 250 Z" fill="${hair}"/>
    <rect x="276" y="228" width="48" height="44" fill="${person.skin}"/>
    <ellipse cx="300" cy="178" rx="66" ry="78" fill="${person.skin}"/>
    <path d="M232 160 Q238 96 300 96 Q362 96 368 160 Q340 126 300 124 Q260 126 232 160 Z" fill="${hair}"/>
    <ellipse cx="300" cy="215" rx="15" ry="6" fill="${lips}"/>`;

  if (person.pose === 'seated') {
    return svg(600, 900, `
      <rect width="600" height="900" fill="#ECEFF3"/>
      <rect y="820" width="600" height="80" fill="#DCE1E7"/>
      <circle cx="285" cy="690" r="150" fill="none" stroke="#6B7280" stroke-width="16"/>
      <rect x="170" y="520" width="250" height="26" rx="10" fill="#4B5563"/>
      <rect x="150" y="300" width="26" height="250" rx="10" fill="#4B5563"/>
      ${head}
      <path d="M205 280 Q300 256 395 280 L405 540 L195 540 Z" fill="${look.clothing}"/>${tie}
      <path d="M195 520 L430 520 L430 580 L195 580 Z" fill="${look.clothing}"/>
      <rect x="395" y="560" width="46" height="220" rx="18" fill="${look.clothing}"/>
      <rect x="380" y="780" width="90" height="22" rx="8" fill="#374151"/>
      <rect x="170" y="290" width="40" height="190" rx="20" fill="${person.skin}"/>
      <rect x="390" y="290" width="40" height="190" rx="20" fill="${person.skin}"/>`);
  }
  return svg(600, 900, `
    <rect width="600" height="900" fill="#ECEFF3"/>
    <rect y="840" width="600" height="60" fill="#DCE1E7"/>
    ${head}
    <rect x="228" y="560" width="62" height="280" rx="22" fill="#3E4552"/>
    <rect x="310" y="560" width="62" height="280" rx="22" fill="#3E4552"/>
    <path d="M205 280 Q300 256 395 280 L425 600 Q300 628 175 600 Z" fill="${look.clothing}"/>${tie}
    <rect x="160" y="290" width="42" height="260" rx="21" fill="${person.skin}"/>
    <rect x="398" y="290" width="42" height="260" rx="21" fill="${person.skin}"/>`);
}

function garmentSvg(shape: Shape, color: string): string {
  const body = {
    dress: `<path d="M150 70 L250 70 L262 160 L330 470 L70 470 L138 160 Z" fill="${color}"/>
      <rect x="150" y="40" width="10" height="34" fill="${color}"/><rect x="240" y="40" width="10" height="34" fill="${color}"/>`,
    gown: `<path d="M155 60 L245 60 L258 170 L360 480 L40 480 L142 170 Z" fill="${color}"/>`,
    suit: `<path d="M110 60 L290 60 L318 300 L82 300 Z" fill="${color}"/>
      <path d="M118 300 L282 300 L290 480 L212 480 L200 330 L188 480 L110 480 Z" fill="${color}"/>
      <path d="M172 60 L228 60 L200 150 Z" fill="#FAFAFA"/>`,
    tie: `<path d="M186 50 L214 50 L224 90 L246 380 L200 440 L154 380 L176 90 Z" fill="${color}"/>
      <path d="M290 120 L340 120 L315 165 Z" fill="${color}"/>`,
    blazer: `<path d="M100 60 L190 60 L178 320 L80 320 Z" fill="${color}"/>
      <path d="M210 60 L300 60 L320 320 L222 320 Z" fill="${color}"/>
      <rect x="60" y="70" width="40" height="230" rx="18" fill="${color}"/>
      <rect x="300" y="70" width="40" height="230" rx="18" fill="${color}"/>`,
  }[shape];
  return svg(400, 500, `<rect width="400" height="500" fill="#FFFFFF"/>${body}`);
}

const svg = (w: number, h: number, body: string) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;

async function toJpeg(markup: string, width: number, height: number): Promise<Buffer> {
  return sharp(Buffer.from(markup)).resize(width, height).jpeg({ quality: 90 }).toBuffer();
}

const sha256 = (bytes: Buffer) => createHash('sha256').update(bytes).digest('hex');
