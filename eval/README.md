# Inclusion evaluation

Scripts that run the same garments on standing and seated test photos and record
success, silent failure (garment not applied), identity drift and latency.

- Test photos stay local in `eval/photos/` (git-ignored). Only consenting adults.
- Before upload, every photo is rotated, resized to the feature's documented limits
  and stripped of metadata (including GPS location).
- Aggregated result tables are committed in `eval/results/` and published in the
  app and the main README. People appear only as ids (p1, p2, ...).

## Kill tests

Three early questions: do seated photos work with apparel try-on, what do makeup and
hair color cost, and does the face stay the same across garments?

Documented limit to keep in mind: the AI Clothes docs ask for a person "facing forward
in a standing position (no sitting or crouching)". The seated runs measure what that
means in practice, and the `seated-mitigation` runs try an upper-body crop.

1. Put photos in `eval/photos/people/` and garment images in `eval/photos/garments/`
   (JPG or PNG; product shots on a plain background work best).
2. Copy `kill-tests/manifest.example.json` to `eval/photos/kill-tests.json` and edit it.
3. Dry run (free): `npm --prefix api run kill-tests`. It prints each run, its cost,
   problems with the photos and your unit balance.
4. Spend units: `npm --prefix api run kill-tests -- --run --max-units=18`.
   Runs that already have a result for the same inputs are skipped, never paid twice.
5. Look at `eval/photos/results/` and fill in `review` (garment applied, same face)
   in `eval/results/kill-tests.json`, then run the dry run again to refresh the table.

Unit prices (from `GET /s2s/v2.0/credit/feature-cost`, 2026-09-30): apparel 2,
makeup 1, hair color 1 per result.
