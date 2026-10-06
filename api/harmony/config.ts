// Every harmony threshold lives here so it can be tuned in one place.
// Distances are CIEDE2000 (ΔE00): about 1 is the smallest difference most
// people notice side by side; above ~10 colors read as clearly different.

export const HARMONY_CONFIG = {
  /** ΔE00 below this: the two colors read as the same color, an intentional match. */
  matchMax: 2.0,

  /**
   * ΔE00 from matchMax up to this value: close but not equal. Side by side in one
   * photo this reads as a mistake ("almost the same pink"), so it is a warning.
   */
  nearMissMax: 8.0,

  /** Colors with chroma (C*) below this have no meaningful hue: black, white, grays. */
  neutralChromaMax: 10,

  /**
   * Two chromatic colors whose CIELAB hue angles are within this many degrees of
   * opposite (180°) are complementary. CIELAB puts blue and orange about 140° apart,
   * so the tolerance is wide enough to include that classic pairing.
   */
  complementaryTolerance: 45,

  /**
   * If both colors are darker than this lightness (L*), small differences vanish
   * in event lighting and photos, so a near-miss between them is treated as a match.
   */
  darkPairLightnessMax: 22,

  /** Pair scores (0..100). The group score is the weakest pair's score. */
  scores: {
    matched: 100,
    complementary: 95,
    contrast: 85,
    /** A near-miss scores between these: worst in the middle of the band, better near its edges. */
    nearMissWorst: 20,
    nearMissBest: 60,
  },

  extraction: {
    /** Images are shrunk to this many pixels on the long side before clustering. */
    sampleSize: 96,
    /** Number of k-means clusters before similar clusters are merged. */
    clusters: 5,
    /** Clusters closer than this ΔE00 are merged into one color. */
    mergeDeltaE: 6,
    /** Colors covering less of the garment than this share are dropped as accents. */
    minShare: 0.08,
    /**
     * Pixels within this ΔE00 of the border's median color count as background.
     * Kept small so pale garments (ivory, champagne) on a white background survive.
     */
    backgroundDeltaE: 8,
    /** The background is only removed if at least this share of the border is uniform. */
    uniformBorderShare: 0.6,
  },

  checks: {
    /** A render whose closest color is farther than this from the catalogue color gets a "check this render" note. */
    driftDeltaE: 14,
    /** Mean per-pixel ΔE (CIE76) between photo and render below this: the garment was probably not applied. */
    unchangedMeanDelta: 3,
  },

  /** Dress code: how close an outfit's main color must be to one of the event's colors. */
  dressCode: {
    /** ΔE00 up to this: the outfit is in the dress code (a shade a guest would call the same color). */
    onMax: 10,
    /** Up to this: close to the dress code, worth a second look. Farther: outside it. */
    closeMax: 20,
  },

  /** Photo quality gate, run on the participant photo after upload. */
  photo: {
    minLongSide: 640,
    minShortSide: 480,
    /** Long side divided by short side. Very tall or wide crops are rejected by try-on engines. */
    maxAspectRatio: 2.4,
    /** Mean lightness (L*) below this: too dark. */
    darkMeanL: 28,
    /** Mean lightness (L*) above this: overexposed. */
    brightMeanL: 90,
    /** Standard deviation of L* below this: flat, washed-out photo. */
    lowContrastStdL: 10,
    /**
     * Mean lightness of the central (torso) area below this: dark clothing on the
     * photo, which is known to make apparel try-on fail silently.
     */
    darkClothingMeanL: 30,
  },

  /** Color vision view: how the group's outfits look with a color vision deficiency. */
  vision: {
    /**
     * Two outfits that are clearly different for typical vision (above nearMissMax)
     * but at or below this ΔE00 in the simulated view look alike to that viewer.
     * Informational only: it never changes the group score.
     */
    lookAlikeMax: 8.0,
  },
} as const;

export type HarmonyConfig = typeof HARMONY_CONFIG;
