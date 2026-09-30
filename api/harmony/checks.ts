import sharp from 'sharp';
import { ciede2000, rgbToLab, type Lab } from './color.js';
import { HARMONY_CONFIG } from './config.js';
import { clusterColors, sampleImage, type DominantColor } from './extract.js';

export type PhotoIssue = 'too_small' | 'too_dark' | 'too_bright' | 'low_contrast' | 'unusual_ratio';
export type PhotoWarning = 'dark_clothing';

export interface PhotoQuality {
  width: number;
  height: number;
  /** Mean L* (0 black .. 100 white). */
  brightness: number;
  /** Standard deviation of L*. */
  contrast: number;
  /** Problems that block try-on until the photo is replaced. */
  issues: PhotoIssue[];
  /** Risks worth telling the participant about. */
  warnings: PhotoWarning[];
}

/** Checks a normalized participant photo (already rotated and stripped of metadata). */
export async function checkPhotoQuality(
  image: Uint8Array,
  config: Record<keyof typeof HARMONY_CONFIG.photo, number> = HARMONY_CONFIG.photo,
): Promise<PhotoQuality> {
  const meta = await sharp(image).metadata();
  const width = meta.width ?? 0;
  const height = meta.height ?? 0;
  const sample = await sampleImage(image, 64);
  const lightness = sample.labs.map((lab) => lab[0]);
  const brightness = mean(lightness);
  const contrast = Math.sqrt(mean(lightness.map((l) => (l - brightness) ** 2)));

  const torso: number[] = [];
  for (let y = Math.floor(sample.height * 0.35); y < Math.ceil(sample.height * 0.75); y++) {
    for (let x = Math.floor(sample.width * 0.3); x < Math.ceil(sample.width * 0.7); x++) {
      torso.push(sample.labs[y * sample.width + x]![0]);
    }
  }

  const issues: PhotoIssue[] = [];
  const long = Math.max(width, height);
  const short = Math.min(width, height);
  if (long < config.minLongSide || short < config.minShortSide) issues.push('too_small');
  if (short > 0 && long / short > config.maxAspectRatio) issues.push('unusual_ratio');
  if (brightness < config.darkMeanL) issues.push('too_dark');
  if (brightness > config.brightMeanL) issues.push('too_bright');
  if (contrast < config.lowContrastStdL) issues.push('low_contrast');

  const warnings: PhotoWarning[] = [];
  if (!issues.includes('too_dark') && mean(torso) < config.darkClothingMeanL) warnings.push('dark_clothing');

  return { width, height, brightness: round1(brightness), contrast: round1(contrast), issues, warnings };
}

export interface RenderCheck {
  /** False when the render is almost identical to the photo: the garment was probably not applied. */
  garmentApplied: boolean;
  /** Mean per-pixel CIELAB distance between photo and render. */
  meanChange: number;
  /** Distance from the catalogue garment color to the closest color in the render. */
  garmentDeltaE: number | null;
  /** True when the render's colors drifted away from the catalogue color: "check this render". */
  drift: boolean;
}

/**
 * Compares an apparel render with the photo it was made from. Never changes a
 * harmony score; it only adds notes the participant can act on.
 */
export async function checkApparelRender(
  photo: Uint8Array,
  render: Uint8Array,
  garmentColors: DominantColor[] | null,
  config: Record<keyof typeof HARMONY_CONFIG.checks, number> = HARMONY_CONFIG.checks,
): Promise<RenderCheck> {
  const [a, b] = await Promise.all([fixedGrid(photo), fixedGrid(render)]);
  let total = 0;
  for (let i = 0; i < a.length; i++) {
    total += Math.hypot(a[i]![0] - b[i]![0], a[i]![1] - b[i]![1], a[i]![2] - b[i]![2]);
  }
  const meanChange = total / a.length;

  let garmentDeltaE: number | null = null;
  const garment = garmentColors?.[0];
  if (garment) {
    const renderColors = clusterColors((await sampleImage(render, 64)).labs, {
      ...HARMONY_CONFIG.extraction,
      clusters: 8,
      minShare: 0.02,
    });
    const distances = renderColors.map((c) => ciede2000(c.lab, garment.lab));
    garmentDeltaE = distances.length > 0 ? round1(Math.min(...distances)) : null;
  }

  return {
    garmentApplied: meanChange >= config.unchangedMeanDelta,
    meanChange: round1(meanChange),
    garmentDeltaE,
    drift: garmentDeltaE !== null && garmentDeltaE > config.driftDeltaE,
  };
}

/** Both images on the same 48x64 grid, so pixels can be compared one to one. */
async function fixedGrid(image: Uint8Array): Promise<Lab[]> {
  const data = await sharp(image).rotate().resize(48, 64, { fit: 'fill' }).removeAlpha().raw().toBuffer();
  const labs: Lab[] = [];
  for (let i = 0; i < data.length; i += 3) labs.push(rgbToLab([data[i]!, data[i + 1]!, data[i + 2]!]));
  return labs;
}

const mean = (values: number[]) => (values.length ? values.reduce((s, v) => s + v, 0) / values.length : 0);
const round1 = (value: number) => Math.round(value * 10) / 10;
