import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import { ciede2000, hexToLab } from './color.js';
import { extractDominantColors } from './extract.js';

/** A product-style image: plain background with a garment-shaped block and a small accent. */
async function productShot(background: string, garment: string, accent?: string) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="400" height="500">
    <rect width="400" height="500" fill="${background}"/>
    <path d="M140 40 L260 40 L300 460 L100 460 Z" fill="${garment}"/>
    ${accent ? `<rect x="185" y="60" width="30" height="40" fill="${accent}"/>` : ''}
  </svg>`;
  return sharp(Buffer.from(svg)).jpeg({ quality: 95 }).toBuffer();
}

const near = (hex: string, target: string, max = 3) => ciede2000(hexToLab(hex), hexToLab(target)) < max;

describe('extractDominantColors', () => {
  it('finds the garment color and ignores a plain background', async () => {
    const colors = await extractDominantColors(await productShot('#F4F4F4', '#B0304A', '#1B1B1B'));
    expect(near(colors[0]!.hex, '#B0304A')).toBe(true);
    expect(colors[0]!.share).toBeGreaterThan(0.8);
    expect(colors.some((c) => near(c.hex, '#F4F4F4', 5))).toBe(false);
  });

  it('works for a white garment on a white background', async () => {
    const colors = await extractDominantColors(await productShot('#FFFFFF', '#FDFDFD'));
    expect(near(colors[0]!.hex, '#FFFFFF')).toBe(true);
  });

  it('uses transparency when the product is cut out', async () => {
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
      <circle cx="100" cy="100" r="80" fill="#2E8B57"/></svg>`;
    const png = await sharp(Buffer.from(svg)).png().toBuffer();
    const colors = await extractDominantColors(png);
    expect(colors).toHaveLength(1);
    expect(near(colors[0]!.hex, '#2E8B57')).toBe(true);
  });

  it('is deterministic', async () => {
    const image = await productShot('#EEEEEE', '#3A6EA5', '#F2C14E');
    expect(await extractDominantColors(image)).toEqual(await extractDominantColors(image));
  });
});
