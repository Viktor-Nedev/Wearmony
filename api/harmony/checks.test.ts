import sharp from 'sharp';
import { describe, expect, it } from 'vitest';
import { hexToLab } from './color.js';
import { checkApparelRender, checkPhotoQuality } from './checks.js';

/** A simple portrait: background, head, torso in the given clothing color. */
function portrait(background: string, clothing: string, width = 768, height = 1024) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <rect width="100%" height="100%" fill="${background}"/>
    <circle cx="${width / 2}" cy="${height * 0.2}" r="${width * 0.12}" fill="#D7A98C"/>
    <rect x="${width * 0.25}" y="${height * 0.32}" width="${width * 0.5}" height="${height * 0.6}" fill="${clothing}"/>
  </svg>`;
  return sharp(Buffer.from(svg)).jpeg({ quality: 92 }).toBuffer();
}

const colors = (hex: string) => [{ hex, lab: [...hexToLab(hex)] as [number, number, number], share: 1 }];

describe('checkPhotoQuality', () => {
  it('accepts a well-lit photo', async () => {
    const quality = await checkPhotoQuality(await portrait('#DADDE2', '#6C8EBF'));
    expect(quality.issues).toEqual([]);
    expect(quality.warnings).toEqual([]);
  });

  it('flags small and dark photos', async () => {
    const quality = await checkPhotoQuality(await portrait('#141414', '#161616', 400, 300));
    expect(quality.issues).toEqual(['too_small', 'too_dark']);
  });

  it('flags a flat, washed-out photo', async () => {
    const flat = await sharp({ create: { width: 768, height: 1024, channels: 3, background: '#9A9A9A' } })
      .jpeg()
      .toBuffer();
    expect((await checkPhotoQuality(flat)).issues).toEqual(['low_contrast']);
  });

  it('warns about dark clothing, which can make apparel try-on fail silently', async () => {
    const quality = await checkPhotoQuality(await portrait('#E6E6E6', '#111111'));
    expect(quality.issues).toEqual([]);
    expect(quality.warnings).toEqual(['dark_clothing']);
  });
});

describe('checkApparelRender', () => {
  it('detects a render that is identical to the photo', async () => {
    const photo = await portrait('#DADDE2', '#6C8EBF');
    const check = await checkApparelRender(photo, photo, colors('#B0304A'));
    expect(check.garmentApplied).toBe(false);
    expect(check.drift).toBe(true);
  });

  it('accepts a render where the garment color appears', async () => {
    const photo = await portrait('#DADDE2', '#6C8EBF');
    const render = await portrait('#DADDE2', '#B0304A');
    const check = await checkApparelRender(photo, render, colors('#B0304A'));
    expect(check.garmentApplied).toBe(true);
    expect(check.drift).toBe(false);
    expect(check.garmentDeltaE).toBeLessThan(5);
  });
});
