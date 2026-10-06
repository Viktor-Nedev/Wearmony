// Color math: sRGB <-> CIELAB (D65) and the CIEDE2000 color difference.
// References: CIE 15:2004; G. Sharma, W. Wu, E. N. Dalal, "The CIEDE2000
// color-difference formula" (2005), whose test data the unit tests use.

export type Lab = readonly [number, number, number];
export type Rgb = readonly [number, number, number];

// D65 reference white.
const XN = 0.95047;
const YN = 1.0;
const ZN = 1.08883;
const EPSILON = (6 / 29) ** 3;
const KAPPA_INV = 3 * (6 / 29) ** 2;

const rad = (deg: number) => (deg * Math.PI) / 180;
const deg = (radians: number) => (radians * 180) / Math.PI;

export function hexToRgb(hex: string): Rgb {
  const match = /^#?([0-9a-f]{6})$/i.exec(hex.trim());
  if (!match) throw new Error(`Not a #RRGGBB color: ${hex}`);
  const value = parseInt(match[1]!, 16);
  return [(value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff];
}

export function rgbToHex([r, g, b]: Rgb): string {
  const part = (v: number) => Math.round(Math.min(255, Math.max(0, v))).toString(16).padStart(2, '0');
  return `#${part(r)}${part(g)}${part(b)}`.toUpperCase();
}

/** sRGB channel (0-255) to linear light (0-1). */
export function toLinear(channel: number) {
  const c = channel / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

/** Linear light (0-1) to an sRGB channel (0-255), clamped. */
export function fromLinear(c: number) {
  const v = c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055;
  return Math.min(1, Math.max(0, v)) * 255;
}

const f = (t: number) => (t > EPSILON ? Math.cbrt(t) : t / KAPPA_INV + 4 / 29);
const fInv = (t: number) => (t > 6 / 29 ? t ** 3 : KAPPA_INV * (t - 4 / 29));

export function rgbToLab([r8, g8, b8]: Rgb): Lab {
  const r = toLinear(r8);
  const g = toLinear(g8);
  const b = toLinear(b8);
  const x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
  const y = 0.2126729 * r + 0.7151522 * g + 0.072175 * b;
  const z = 0.0193339 * r + 0.119192 * g + 0.9503041 * b;
  const fx = f(x / XN);
  const fy = f(y / YN);
  const fz = f(z / ZN);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

export function labToRgb([l, a, b]: Lab): Rgb {
  const fy = (l + 16) / 116;
  const x = XN * fInv(fy + a / 500);
  const y = YN * fInv(fy);
  const z = ZN * fInv(fy - b / 200);
  return [
    fromLinear(3.2404542 * x - 1.5371385 * y - 0.4985314 * z),
    fromLinear(-0.969266 * x + 1.8760108 * y + 0.041556 * z),
    fromLinear(0.0556434 * x - 0.2040259 * y + 1.0572252 * z),
  ];
}

export const hexToLab = (hex: string): Lab => rgbToLab(hexToRgb(hex));
export const labToHex = (lab: Lab): string => rgbToHex(labToRgb(lab));

export function chroma([, a, b]: Lab): number {
  return Math.hypot(a, b);
}

/** CIELAB hue angle in degrees, 0..360. */
export function hueAngle([, a, b]: Lab): number {
  if (a === 0 && b === 0) return 0;
  const h = deg(Math.atan2(b, a));
  return h >= 0 ? h : h + 360;
}

/** Smallest angle between two hues, 0..180. */
export function hueDistance(h1: number, h2: number): number {
  const d = Math.abs(h1 - h2) % 360;
  return d > 180 ? 360 - d : d;
}

/** CIEDE2000 color difference with kL = kC = kH = 1. */
export function ciede2000(lab1: Lab, lab2: Lab): number {
  const [l1, a1, b1] = lab1;
  const [l2, a2, b2] = lab2;

  const cBar = (Math.hypot(a1, b1) + Math.hypot(a2, b2)) / 2;
  const cBar7 = cBar ** 7;
  const g = 0.5 * (1 - Math.sqrt(cBar7 / (cBar7 + 25 ** 7)));
  const a1p = (1 + g) * a1;
  const a2p = (1 + g) * a2;
  const c1p = Math.hypot(a1p, b1);
  const c2p = Math.hypot(a2p, b2);
  const h1p = hueAngle([l1, a1p, b1]);
  const h2p = hueAngle([l2, a2p, b2]);

  const dLp = l2 - l1;
  const dCp = c2p - c1p;
  let dhp = 0;
  if (c1p * c2p !== 0) {
    dhp = h2p - h1p;
    if (dhp > 180) dhp -= 360;
    else if (dhp < -180) dhp += 360;
  }
  const dHp = 2 * Math.sqrt(c1p * c2p) * Math.sin(rad(dhp / 2));

  const lBarp = (l1 + l2) / 2;
  const cBarp = (c1p + c2p) / 2;
  let hBarp = h1p + h2p;
  if (c1p * c2p !== 0) {
    if (Math.abs(h1p - h2p) <= 180) hBarp = (h1p + h2p) / 2;
    else if (h1p + h2p < 360) hBarp = (h1p + h2p + 360) / 2;
    else hBarp = (h1p + h2p - 360) / 2;
  }

  const t =
    1 -
    0.17 * Math.cos(rad(hBarp - 30)) +
    0.24 * Math.cos(rad(2 * hBarp)) +
    0.32 * Math.cos(rad(3 * hBarp + 6)) -
    0.2 * Math.cos(rad(4 * hBarp - 63));
  const dTheta = 30 * Math.exp(-(((hBarp - 275) / 25) ** 2));
  const cBarp7 = cBarp ** 7;
  const rC = 2 * Math.sqrt(cBarp7 / (cBarp7 + 25 ** 7));
  const sL = 1 + (0.015 * (lBarp - 50) ** 2) / Math.sqrt(20 + (lBarp - 50) ** 2);
  const sC = 1 + 0.045 * cBarp;
  const sH = 1 + 0.015 * cBarp * t;
  const rT = -Math.sin(rad(2 * dTheta)) * rC;

  const lTerm = dLp / sL;
  const cTerm = dCp / sC;
  const hTerm = dHp / sH;
  return Math.sqrt(lTerm ** 2 + cTerm ** 2 + hTerm ** 2 + rT * cTerm * hTerm);
}
