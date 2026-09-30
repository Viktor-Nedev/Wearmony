import { chroma, hueAngle, type Lab } from './color.js';

// Plain color names for explanations. The client translates the keys; the
// backend composes English sentences from the same keys.

export type ColorBase =
  | 'black'
  | 'white'
  | 'gray'
  | 'beige'
  | 'brown'
  | 'red'
  | 'burgundy'
  | 'pink'
  | 'orange'
  | 'yellow'
  | 'olive'
  | 'green'
  | 'teal'
  | 'blue'
  | 'navy'
  | 'purple'
  | 'lavender'
  | 'magenta';

export type ColorModifier = 'light' | 'dark' | 'muted' | null;

export interface ColorName {
  base: ColorBase;
  modifier: ColorModifier;
  /** English label, e.g. "dark green". */
  label: string;
}

const name = (base: ColorBase, modifier: ColorModifier = null): ColorName => ({
  base,
  modifier,
  label: modifier ? `${modifier} ${base}` : base,
});

export function nameColor(lab: Lab): ColorName {
  const [l] = lab;
  const c = chroma(lab);
  const h = hueAngle(lab);

  if (c < 8) {
    if (l < 20) return name('black');
    if (l > 88) return name('white');
    return name('gray', l < 40 ? 'dark' : l > 70 ? 'light' : null);
  }
  // Pale, low-chroma warm colors (cream, sand) and dark warm colors (chocolate, tan).
  if (h >= 40 && h < 115 && l > 68 && c < 28) return name('beige');
  if (h >= 25 && h < 80 && l < 48 && c < 55) return name('brown', l < 25 ? 'dark' : null);
  // Pale bluish purples.
  if (h >= 250 && h < 335 && l > 72 && c < 45) return name('lavender');

  const modifier: ColorModifier = c < 22 ? 'muted' : l > 72 ? 'light' : l < 40 ? 'dark' : null;

  if (h >= 345 || h < 28) {
    if (l > 62) return name('pink', c < 22 ? 'muted' : null);
    if (l < 36) return name('burgundy');
    return name('red', modifier);
  }
  if (h < 45) return l < 36 ? name('burgundy') : name('red', modifier);
  if (h < 75) return name('orange', modifier);
  if (h < 105) return l < 55 ? name('olive') : name('yellow', modifier);
  if (h < 165) return name('green', modifier);
  if (h < 225) return name('teal', modifier);
  // sRGB blue and navy sit near 306 degrees; purple and magenta near 328.
  if (h < 315) return l < 30 ? name('navy') : name('blue', modifier);
  if (h < 335) return name('purple', modifier);
  return l > 62 ? name('pink') : name('magenta', modifier);
}
