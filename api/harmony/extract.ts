import sharp from 'sharp';
import { ciede2000, labToHex, rgbToLab, type Lab } from './color.js';
import { HARMONY_CONFIG } from './config.js';

export interface DominantColor {
  hex: string;
  lab: [number, number, number];
  /** Share of the garment's pixels, 0..1. */
  share: number;
}

export type ExtractionConfig = Record<keyof typeof HARMONY_CONFIG.extraction, number>;

export interface SampledImage {
  width: number;
  height: number;
  labs: Lab[];
  opaque: boolean[];
}

/** Shrinks the image and converts every pixel to CIELAB. */
export async function sampleImage(image: Uint8Array, size: number): Promise<SampledImage> {
  const { data, info } = await sharp(image)
    .rotate()
    .resize(size, size, { fit: 'inside' })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  const labs: Lab[] = [];
  const opaque: boolean[] = [];
  for (let i = 0; i < data.length; i += 4) {
    labs.push(rgbToLab([data[i]!, data[i + 1]!, data[i + 2]!]));
    opaque.push(data[i + 3]! >= 128);
  }
  return { width: info.width, height: info.height, labs, opaque };
}

/**
 * Dominant colors of a catalogue garment image, largest first.
 * The background is removed first: transparent pixels, or pixels close to a
 * uniform border color (typical product shots). Busy photos fall back to the
 * central area of the image.
 */
export async function extractDominantColors(
  image: Uint8Array,
  config: ExtractionConfig = HARMONY_CONFIG.extraction,
): Promise<DominantColor[]> {
  const sample = await sampleImage(image, config.sampleSize);
  return clusterColors(selectForeground(sample, config), config);
}

export function selectForeground(sample: SampledImage, config: ExtractionConfig = HARMONY_CONFIG.extraction): Lab[] {
  const { width, height, labs, opaque } = sample;

  if (opaque.some((isOpaque) => !isOpaque)) {
    const visible = labs.filter((_, i) => opaque[i]);
    if (visible.length > 0) return visible;
  }

  const at = (x: number, y: number) => labs[y * width + x]!;
  const border: Lab[] = [];
  for (let x = 0; x < width; x++) border.push(at(x, 0), at(x, height - 1));
  for (let y = 1; y < height - 1; y++) border.push(at(0, y), at(width - 1, y));

  const background = medianLab(border);
  const uniform = border.filter((p) => ciede2000(p, background) < config.backgroundDeltaE).length / border.length;
  if (uniform >= config.uniformBorderShare) {
    const garment = labs.filter((p) => ciede2000(p, background) >= config.backgroundDeltaE);
    // A garment in the background's own color (white dress on white) removes almost
    // everything; then the background color is the garment color.
    return garment.length >= labs.length * 0.05 ? garment : labs;
  }

  const central: Lab[] = [];
  for (let y = Math.floor(height * 0.2); y < Math.ceil(height * 0.8); y++) {
    for (let x = Math.floor(width * 0.2); x < Math.ceil(width * 0.8); x++) central.push(at(x, y));
  }
  return central;
}

/** Deterministic k-means in CIELAB, then merges similar clusters and drops small accents. */
export function clusterColors(pixels: Lab[], config: ExtractionConfig = HARMONY_CONFIG.extraction): DominantColor[] {
  if (pixels.length === 0) return [];
  const random = mulberry32(42);
  const centers: Lab[] = [pixels[Math.floor(random() * pixels.length)]!];

  // k-means++ seeding.
  while (centers.length < Math.min(config.clusters, pixels.length)) {
    const weights = pixels.map((p) => Math.min(...centers.map((c) => distance2(p, c))));
    const total = weights.reduce((sum, w) => sum + w, 0);
    if (total === 0) break;
    let target = random() * total;
    let index = 0;
    while (index < pixels.length - 1 && target > weights[index]!) target -= weights[index++]!;
    centers.push(pixels[index]!);
  }

  const assignment = new Int32Array(pixels.length).fill(-1);
  for (let iteration = 0; iteration < 30; iteration++) {
    let changed = false;
    pixels.forEach((p, i) => {
      let best = 0;
      for (let c = 1; c < centers.length; c++) {
        if (distance2(p, centers[c]!) < distance2(p, centers[best]!)) best = c;
      }
      if (assignment[i] !== best) {
        assignment[i] = best;
        changed = true;
      }
    });
    if (!changed) break;
    for (let c = 0; c < centers.length; c++) {
      const members = pixels.filter((_, i) => assignment[i] === c);
      if (members.length > 0) centers[c] = meanLab(members);
    }
  }

  let clusters = centers.map((center, c) => ({ center, count: assignment.filter((a) => a === c).length }));
  clusters = clusters.filter((cluster) => cluster.count > 0);

  // Merge clusters that read as the same color.
  for (;;) {
    let pair: [number, number] | null = null;
    let closest = config.mergeDeltaE;
    for (let i = 0; i < clusters.length; i++) {
      for (let j = i + 1; j < clusters.length; j++) {
        const d = ciede2000(clusters[i]!.center, clusters[j]!.center);
        if (d < closest) {
          closest = d;
          pair = [i, j];
        }
      }
    }
    if (!pair) break;
    const [a, b] = [clusters[pair[0]]!, clusters[pair[1]]!];
    const count = a.count + b.count;
    const center: Lab = [0, 1, 2].map((k) => (a.center[k]! * a.count + b.center[k]! * b.count) / count) as unknown as Lab;
    clusters = clusters.filter((_, i) => i !== pair![0] && i !== pair![1]).concat({ center, count });
  }

  return clusters
    .map(({ center, count }) => ({
      hex: labToHex(center),
      lab: center.map((v) => Math.round(v * 100) / 100) as [number, number, number],
      share: Math.round((count / pixels.length) * 1000) / 1000,
    }))
    .filter((color) => color.share >= config.minShare)
    .sort((a, b) => b.share - a.share);
}

function distance2(a: Lab, b: Lab) {
  return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2;
}

function meanLab(values: Lab[]): Lab {
  const sum = values.reduce<[number, number, number]>((acc, v) => [acc[0] + v[0], acc[1] + v[1], acc[2] + v[2]], [0, 0, 0]);
  return [sum[0] / values.length, sum[1] / values.length, sum[2] / values.length];
}

function medianLab(values: Lab[]): Lab {
  const median = (k: number) => {
    const sorted = values.map((v) => v[k]!).sort((x, y) => x - y);
    return sorted[Math.floor(sorted.length / 2)]!;
  };
  return [median(0), median(1), median(2)];
}

/** Small seeded PRNG so extraction is reproducible. */
function mulberry32(seed: number) {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
