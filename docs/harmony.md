# Harmony method

The harmony engine answers one question: *will these colors look right next to each other in the group photo?* It is deterministic: the same inputs always give the same result, and every result can be explained in one sentence. Code: [`api/harmony/`](../api/harmony).

## 1. Where colors come from

**Garments**: from the catalogue product image, never from the rendered try-on (renders can drift).

1. The image is shrunk to 96 px on its long side and converted from sRGB to CIELAB (D65).
2. Background removal:
   - transparent pixels are background (cut-out product shots);
   - otherwise, if at least 60% of the border ring is one color, pixels within ΔE00 8 of that color are background (plain studio shots). If that would remove almost everything, the garment *is* the background color (a white dress on white);
   - busy photos fall back to the central 60% of the image.
3. k-means in CIELAB (k-means++ seeding with a fixed seed, so results are reproducible), then clusters closer than ΔE00 6 are merged and clusters under 8% of the garment are dropped as accents.
4. The largest cluster is the garment's primary color.

**Lip and hair color**: exact hex values from the catalogue item, which are also what YouCam receives. No estimation is needed.

## 2. Comparing two colors

CIEDE2000 (ΔE00), implemented from Sharma, Wu and Dalal (2005) and tested against all 34 of their published pairs to four decimal places.

| Rule | Condition | Score |
| --- | --- | --- |
| matched | ΔE00 < 2 | 100 |
| near-miss (warning) | 2 ≤ ΔE00 < 8 | 20 to 60: worst in the middle of the band |
| complementary | ΔE00 ≥ 8, both colors chromatic (C* ≥ 10), hue angles 135° to 180° apart | 95 |
| contrast | everything else | 85 |

Two very dark colors (both L* < 22) within the near-miss band count as matched: in event lighting and photos their difference disappears.

CIELAB places sRGB blue and orange about 140° apart, not 180°, so the complementary tolerance is ±45° around opposite.

## 3. What is compared

- Every pair of participants: primary outfit colors. Partners (couples) are marked and listed first among equal scores.
- Each participant's lip color and hair color against their own outfit.

## 4. Group score

The group score is the **weakest pair's score**, not an average: one clash is enough to spoil the photo, and averaging would hide it. The report names the people involved.

## 5. Explanations

Every finding has one plain sentence, built from structured fields (names, color names, relation, ΔE) so the app can show it in English or Bulgarian. Color names come from a small deterministic mapping of lightness, chroma and hue angle (`names.ts`).

An optional plain-language summary (Gemini) receives only the computed facts, is told to talk about colors only and never about bodies or skin, and is labeled in the app. It never changes a score.

## 6. Fix suggestions

For a near-miss, the engine looks for swaps from the event's own catalogue that would remove it ([`suggest.ts`](../api/harmony/suggest.ts)):

1. Only the people in the comparison whose look is not locked can change. For a pair that means a new garment for either person; for someone's own lip or hair color, a new lip or hair color only (the outfit stays).
2. Each candidate item is put on that person and the **whole group's harmony is recomputed** with the same engine. A swap counts only if the near-miss becomes a match, a complementary pair or a contrast.
3. Swaps are ranked by: fewest near-misses left in the group, within the per-person budget, highest group score, the same kind of garment (a dress for a dress), the best result for the pair itself (an exact match before a contrast), smallest price change. At most two ideas per person, so both partners get options.

Each suggestion states what it would change: the new relation and ΔE, the group score before and after, and the price difference. A participant can switch to their own suggestion with one tap; the new preview is a separate, explicit step because a live render spends units. Suggestions for someone else can be copied and sent to them.

## 7. Render checks

These never change a score; they only add notes.

- **Garment not applied**: the render and the photo are compared pixel by pixel on a 48×64 grid in CIELAB; a mean change under 3 means the outfit was probably not applied (YouCam can return the photo unchanged, for example when the original clothing is dark or bulky).
- **Color drift**: the closest color in the render to the catalogue color; farther than ΔE00 14 gives a "check this render" note.

## 8. Photo quality gate

After upload, before any try-on: minimum size (640 × 480), aspect ratio (≤ 2.4), mean lightness (dark < 28, overexposed > 90), contrast (L* standard deviation < 10), and a warning when the torso area is very dark (dark clothing). Size and ratio block the photo; the rest is advice the participant can act on.

All thresholds: [`api/harmony/config.ts`](../api/harmony/config.ts).
