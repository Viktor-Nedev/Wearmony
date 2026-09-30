# YouCam API integration

Everything that knows YouCam paths, payloads or response shapes is in [`api/youcam/`](../api/youcam):

| File | Role |
| --- | --- |
| `live.ts` | HTTP client: credit, feature costs, file registration and upload, task create and status. Retries HTTP 429. |
| `specs.ts` | Documented image limits per feature, target image sizes, unit prices, request bodies. |
| `live-provider.ts` | Try-on provider on top of the client: uploads each image once, creates tasks, downloads results, maps engine error codes to reasons the app explains. |
| `mock.ts` | Provider with zero network calls for mock mode, tests and the demo. Results are striped overlays, labeled as simulated in the app. |
| `provider.ts` | The interface the render pipeline uses; it never knows which provider it talks to. |

Source of truth: the official documentation at docs.perfectcorp.com (checked 2026-09-30), including the OpenAPI bundles for AI Clothes, AI Makeup VTO, AI Hair Color, File Management and the Unit System.

## Flow for one look

```
photo ──normalize──► POST /s2s/v2.0/file ─► PUT presigned URL
garment image ─────► POST /s2s/v2.0/file ─► PUT presigned URL
POST /s2s/v2.0/task/cloth-v4 {src_file_id, ref_file_id, garment_category}
GET  /s2s/v2.0/task/cloth-v4/{task_id}   (every ≥ 8 s, until success or error)
download results.url (valid 2 hours) ─► normalize ─► private storage
   └─► same chain with makeup-vto (lip_color effect), then hair-color (custom palette)
```

- Images are rotated by EXIF, resized to each feature's documented limit (apparel 2048 px long side; makeup and hair 1600 px, since their limit is under 1920 px) and re-encoded without metadata.
- File ids are cached by image content hash for 29 days (YouCam keeps them 30).
- `filter_multi_person` is `off`: the engine uses the largest person, so a bystander does not reject the photo.

## Costs and budget

Prices come from `GET /s2s/v2.0/credit/feature-cost`: AI Clothes V2, V3 and V4 cost 2 units per result, Makeup VTO 1, Hair Color 1 (full or ombre). Before every paid call the ledger checks the per-event cap, the per-participant cap and the live balance (`GET /s2s/v1.0/client/credit`) against an optional reserve.

## Error handling

Engine error codes from the task status are mapped to reasons the app explains in plain words (English and Bulgarian):

| Reason | Codes |
| --- | --- |
| pose not supported | `error_pose`, `error_no_shoulder`, `error_invalid_src`, `error_apply_region_mismatch` |
| face not found | `error_no_face`, `error_face_parsing`, `error_large_face_angle`, `error_face_position_*`, `error_face_angle_invalid` |
| garment not applied | `error_editing_failed` (result too similar to the source) |
| multiple people | `error_multi_person`, `error_multiple_people` |
| image invalid | size, ratio, decode and reference-image errors |
| content rejected | `error_nsfw_content_detected`, `exceed_nsfw_retry_limits` |
| budget exhausted | HTTP 400 `CreditInsufficiency` when creating a task, or a local cap |

Transient problems (network, timeouts after 6 minutes) can be retried from the app; deterministic failures are not retried, so units are not wasted.

Seated participants: when a `full_body` garment fails with a pose or not-applied reason, the step is retried once with `upper_body`. Both attempts are cached separately.

## Fixtures

- `fixtures/youcam/captured/`: real responses from the account, with ids and signed URLs redacted (credit balance, all feature-cost pages). The kill-test runner adds task responses as it runs.
- `fixtures/youcam/docs/`: examples copied from the documentation, kept apart and labeled as such.

## Kill tests and evaluation

[`eval/kill-tests/run.ts`](../eval/kill-tests/run.ts) runs a manifest of photos and garments against the live API. It dry-runs by default (zero units), validates every image against the documented limits first, spends only with `--run`, stops at `--max-units`, never pays twice for the same inputs, records latency and unit use per run, captures redacted fixtures and writes the published inclusion table.
