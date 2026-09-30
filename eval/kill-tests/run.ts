// Kill tests: do seated photos work, what do makeup and hair color cost,
// and does the face stay the same across garments? See eval/README.md.
//
// Dry run (default, spends nothing):  npm --prefix api run kill-tests
// Spend units:                        npm --prefix api run kill-tests -- --run --max-units=18
// Only some runs:                     ... --only=seated-p2-g1,hair-p1

import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readImageInfo } from '../../api/lib/image-size.js';
import { normalizeImage } from '../../api/lib/normalize-image.js';
import {
  createYouCamClient,
  YouCamError,
  type YouCamClient,
  type YouCamFeature,
  type YouCamGarmentCategory,
} from '../../api/youcam/live.js';
import {
  APPAREL_FEATURE,
  checkImage,
  clothTaskBody,
  hairColorTaskBody,
  lipColorTaskBody,
  TARGET_LONG_SIDE,
  UNIT_COST,
} from '../../api/youcam/specs.js';

const ROOT = fileURLToPath(new URL('../../', import.meta.url));
const PHOTOS = join(ROOT, 'eval/photos'); // private, git-ignored
const MANIFEST = join(PHOTOS, 'kill-tests.json');
const FILE_CACHE = join(PHOTOS, '.youcam-files.json');
const RESULTS_DIR = join(PHOTOS, 'results');
const REPORT_JSON = join(ROOT, 'eval/results/kill-tests.json'); // committed, no photos or names
const REPORT_MD = join(ROOT, 'eval/results/kill-tests.md');
const FIXTURES = join(ROOT, 'fixtures/youcam/captured');

const POLL_MS = 5_000;
const TIMEOUT_MS = 180_000;
const FILE_ID_TTL_MS = 29 * 24 * 3600 * 1000; // documented retention is 30 days

type Pose = 'standing' | 'seated';

interface Manifest {
  people: Record<string, { file: string; pose: Pose }>;
  garments: Record<string, { file: string; category: YouCamGarmentCategory }>;
  runs: RunSpec[];
}

interface RunSpec {
  id: string;
  /** Free label used in the report, e.g. "seated", "identity", "makeup". */
  test: string;
  person: string;
  garment?: string;
  /** Overrides the garment's category, e.g. upper_body for a seated mitigation. */
  category?: YouCamGarmentCategory;
  lipColor?: string;
  hairColor?: string;
}

interface RunResult {
  id: string;
  test: string;
  person: string;
  pose: Pose;
  feature: YouCamFeature;
  garment: string | null;
  category: YouCamGarmentCategory | null;
  color: string | null;
  inputHash: string;
  state: 'success' | 'error' | 'rejected' | 'timeout';
  errorCode: string | null;
  errorMessage: string | null;
  latencyMs: number;
  unitsSpent: number;
  resultFile: string | null;
  ranAt: string;
  /** Filled in by hand after looking at the result image. */
  review: { garmentApplied: boolean | null; identityKept: boolean | null; notes: string };
}

interface PlannedRun {
  spec: RunSpec;
  feature: YouCamFeature;
  pose: Pose;
  personBytes: Buffer;
  garmentBytes: Buffer | null;
  category: YouCamGarmentCategory | null;
  color: string | null;
  inputHash: string;
  cost: number;
  problems: string[];
  done: boolean;
}

const args = parseArgs(process.argv.slice(2));

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});

async function main() {
  try {
    process.loadEnvFile(join(ROOT, '.env'));
  } catch {
    // Fall through to the check below.
  }
  const apiKey = process.env.YOUCAM_API_KEY;
  const baseUrl = process.env.YOUCAM_API_BASE;
  if (!apiKey || !baseUrl) throw new Error('Set YOUCAM_API_KEY and YOUCAM_API_BASE in .env');
  if (!existsSync(MANIFEST)) {
    throw new Error(`Missing ${MANIFEST}. Copy eval/kill-tests/manifest.example.json there and add your photos.`);
  }

  const youcam = createYouCamClient({ apiKey, baseUrl, fetch: recordingFetch(new URL(baseUrl).host) });
  const manifest = JSON.parse(readFileSync(MANIFEST, 'utf8')) as Manifest;
  const report = loadReport();
  const costs = await featureCosts(youcam);
  const balance = (await youcam.getCredit()).total;

  const selected = manifest.runs.filter((run) => !args.only || args.only.includes(run.id));
  const plan: PlannedRun[] = [];
  for (const spec of selected) plan.push(await planRun(spec, manifest, costs, report));
  printPlan(plan, balance);

  if (!args.run) {
    // Refresh the table so hand-written reviews show up without spending anything.
    if (Object.keys(report).length > 0) saveReport(report);
    console.log('\nDry run: nothing was sent. Add --run to spend units.');
    return;
  }

  const fileIds = loadFileCache();
  let spent = 0;
  for (const planned of plan) {
    if (planned.done || planned.problems.length > 0) continue;
    if (spent + planned.cost > args.maxUnits) {
      console.log(`Stopping: ${planned.spec.id} would exceed --max-units=${args.maxUnits}.`);
      break;
    }
    const result = await execute(youcam, planned, fileIds);
    spent += result.unitsSpent;
    report[result.id] = result;
    saveReport(report);
    console.log(
      `${result.id}: ${result.state}${result.errorCode ? ` (${result.errorCode})` : ''}, ` +
        `${(result.latencyMs / 1000).toFixed(1)} s, ${result.unitsSpent} units`,
    );
    if (result.errorCode === 'CreditInsufficiency') break;
  }

  const after = (await youcam.getCredit()).total;
  console.log(`\nUnits: ${balance} before, ${after} after. Report: eval/results/kill-tests.md`);
  console.log('Open eval/photos/results/ and fill in "review" in eval/results/kill-tests.json.');
}

async function planRun(
  spec: RunSpec,
  manifest: Manifest,
  costs: Map<string, number>,
  report: Record<string, RunResult>,
): Promise<PlannedRun> {
  const problems: string[] = [];
  const person = manifest.people[spec.person];
  if (!person) throw new Error(`${spec.id}: unknown person "${spec.person}"`);

  const kinds = [spec.garment, spec.lipColor, spec.hairColor].filter(Boolean).length;
  if (kinds !== 1) throw new Error(`${spec.id}: set exactly one of garment, lipColor, hairColor`);

  const feature: YouCamFeature = spec.garment ? APPAREL_FEATURE : spec.lipColor ? 'makeup-vto' : 'hair-color';
  const color = spec.lipColor ?? spec.hairColor ?? null;
  if (color && !/^#[0-9a-fA-F]{6}$/.test(color)) problems.push(`color ${color} is not #RRGGBB`);

  // Rotated, resized to the feature's limits and stripped of metadata before anything is uploaded.
  const prepare = async (file: string) => (await normalizeImage(readPhoto(file), TARGET_LONG_SIDE[feature])).bytes;

  const personBytes = await prepare(person.file);
  problems.push(...checkImage(feature, readImageInfo(personBytes), personBytes.length).map((p) => `photo: ${p}`));

  let garmentBytes: Buffer | null = null;
  let category: YouCamGarmentCategory | null = null;
  if (spec.garment) {
    const garment = manifest.garments[spec.garment];
    if (!garment) throw new Error(`${spec.id}: unknown garment "${spec.garment}"`);
    garmentBytes = await prepare(garment.file);
    category = spec.category ?? garment.category;
    problems.push(...checkImage(feature, readImageInfo(garmentBytes), garmentBytes.length).map((p) => `garment: ${p}`));
  }

  const inputHash = sha256(
    Buffer.concat([personBytes, garmentBytes ?? Buffer.alloc(0), Buffer.from(`${feature}|${category}|${color}`)]),
  );
  const previous = report[spec.id];
  const done = previous?.inputHash === inputHash && previous.state !== 'timeout';

  return {
    spec,
    feature,
    pose: person.pose,
    personBytes,
    garmentBytes,
    category,
    color,
    inputHash,
    cost: costs.get(feature) ?? UNIT_COST[feature],
    problems,
    done,
  };
}

async function execute(youcam: YouCamClient, planned: PlannedRun, fileIds: FileCache): Promise<RunResult> {
  const { spec, feature } = planned;
  const base: Omit<RunResult, 'state' | 'errorCode' | 'errorMessage' | 'latencyMs' | 'unitsSpent' | 'resultFile'> = {
    id: spec.id,
    test: spec.test,
    person: spec.person,
    pose: planned.pose,
    feature,
    garment: spec.garment ?? null,
    category: planned.category,
    color: planned.color,
    inputHash: planned.inputHash,
    ranAt: new Date().toISOString(),
    review: { garmentApplied: null, identityKept: null, notes: '' },
  };

  const srcFileId = await uploadOnce(youcam, planned.personBytes, fileIds);
  const refFileId = planned.garmentBytes ? await uploadOnce(youcam, planned.garmentBytes, fileIds) : null;
  const body =
    refFileId && planned.category
      ? clothTaskBody(srcFileId, refFileId, planned.category)
      : spec.lipColor
        ? lipColorTaskBody(srcFileId, spec.lipColor)
        : hairColorTaskBody(srcFileId, spec.hairColor!);

  const before = (await youcam.getCredit()).total;
  const started = Date.now();
  const unitsSince = async () => Math.round((before - (await youcam.getCredit()).total) * 100) / 100;

  let taskId: string;
  try {
    taskId = await youcam.createTask(feature, body);
  } catch (error) {
    if (!(error instanceof YouCamError)) throw error;
    return {
      ...base,
      state: 'rejected',
      errorCode: error.code,
      errorMessage: error.message,
      latencyMs: Date.now() - started,
      unitsSpent: await unitsSince(),
      resultFile: null,
    };
  }

  while (Date.now() - started < TIMEOUT_MS) {
    await new Promise((resolve) => setTimeout(resolve, POLL_MS));
    const task = await youcam.getTask(feature, taskId);
    if (task.state === 'running') continue;

    const latencyMs = Date.now() - started;
    const resultFile = task.resultUrl ? await download(task.resultUrl, spec.id) : null;
    return {
      ...base,
      state: task.state,
      errorCode: task.errorCode,
      errorMessage: task.errorMessage,
      latencyMs,
      unitsSpent: await unitsSince(),
      resultFile,
    };
  }
  return {
    ...base,
    state: 'timeout',
    errorCode: null,
    errorMessage: `no result after ${TIMEOUT_MS / 1000} s`,
    latencyMs: TIMEOUT_MS,
    unitsSpent: await unitsSince(),
    resultFile: null,
  };
}

type FileCache = Record<string, { fileId: string; uploadedAt: number }>;

async function uploadOnce(youcam: YouCamClient, bytes: Buffer, cache: FileCache): Promise<string> {
  const hash = sha256(bytes);
  const cached = cache[hash];
  if (cached && Date.now() - cached.uploadedAt < FILE_ID_TTL_MS) return cached.fileId;

  const info = readImageInfo(bytes);
  const png = info?.format === 'png';
  // Random-looking name: the real file name never leaves this machine.
  const registered = await youcam.registerFile({
    contentType: png ? 'image/png' : 'image/jpg',
    fileName: `${hash.slice(0, 16)}.${png ? 'png' : 'jpg'}`,
    size: bytes.length,
  });
  await youcam.uploadFile(registered.upload, new Uint8Array(bytes));
  cache[hash] = { fileId: registered.fileId, uploadedAt: Date.now() };
  writeFileSync(FILE_CACHE, JSON.stringify(cache, null, 2));
  return registered.fileId;
}

async function download(url: string, id: string): Promise<string> {
  const response = await fetch(url);
  const type = response.headers.get('content-type') ?? '';
  const ext = type.includes('png') ? 'png' : 'jpg';
  mkdirSync(RESULTS_DIR, { recursive: true });
  writeFileSync(join(RESULTS_DIR, `${id}.${ext}`), Buffer.from(await response.arrayBuffer()));
  return `results/${id}.${ext}`;
}

async function featureCosts(youcam: YouCamClient): Promise<Map<string, number>> {
  const byFeature = new Map<string, number>();
  for (const cost of await youcam.getFeatureCosts()) {
    const feature = cost.path.split('/task/')[1];
    // Keep the highest price when a feature has several SKUs (e.g. hair color modes).
    if (feature) byFeature.set(feature, Math.max(byFeature.get(feature) ?? 0, cost.amount));
  }
  return byFeature;
}

function printPlan(plan: PlannedRun[], balance: number) {
  console.log('Run'.padEnd(24), 'Feature'.padEnd(11), 'Pose'.padEnd(9), 'Units', ' Status');
  let total = 0;
  for (const p of plan) {
    const status = p.done ? 'done (cached result, skipped)' : p.problems.length ? `invalid: ${p.problems.join('; ')}` : 'ready';
    if (!p.done && !p.problems.length) total += p.cost;
    console.log(p.spec.id.padEnd(24), p.feature.padEnd(11), p.pose.padEnd(9), String(p.cost).padStart(5), ` ${status}`);
  }
  console.log(`\nPlanned: ${total} units. Balance: ${balance} units. Cap: --max-units=${args.maxUnits}.`);
}

function loadReport(): Record<string, RunResult> {
  if (!existsSync(REPORT_JSON)) return {};
  const runs = JSON.parse(readFileSync(REPORT_JSON, 'utf8')) as RunResult[];
  return Object.fromEntries(runs.map((run) => [run.id, run]));
}

function saveReport(report: Record<string, RunResult>) {
  const runs = Object.values(report).sort((a, b) => a.id.localeCompare(b.id));
  mkdirSync(join(ROOT, 'eval/results'), { recursive: true });
  writeFileSync(REPORT_JSON, JSON.stringify(runs, null, 2) + '\n');
  writeFileSync(REPORT_MD, renderMarkdown(runs));
}

function renderMarkdown(runs: RunResult[]): string {
  const yesNo = (value: boolean | null) => (value === null ? '?' : value ? 'yes' : 'no');
  const rate = (pose: Pose) => {
    const apparel = runs.filter((r) => r.feature.startsWith('cloth') && r.pose === pose);
    const ok = apparel.filter((r) => r.state === 'success' && r.review.garmentApplied !== false).length;
    return `${ok} of ${apparel.length}`;
  };
  const rows = runs.map((r) =>
    [
      r.id,
      r.test,
      r.pose,
      r.feature,
      r.category ?? r.color ?? '',
      r.state,
      r.errorCode ?? '',
      (r.latencyMs / 1000).toFixed(1),
      r.unitsSpent,
      yesNo(r.review.garmentApplied),
      yesNo(r.review.identityKept),
    ].join(' | '),
  );
  return [
    '# Kill test results',
    '',
    'Generated by `eval/kill-tests/run.ts`. Photos stay private; people are listed by id only.',
    'A result counts as applied until a human review marks it otherwise ("?" = not reviewed yet).',
    '',
    `Apparel success, standing: ${rate('standing')}. Seated: ${rate('seated')}.`,
    '',
    '| Run | Test | Pose | Feature | Category / color | Result | Error | Latency (s) | Units | Applied | Same face |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
    ...rows.map((row) => `| ${row} |`),
    '',
  ].join('\n');
}

function loadFileCache(): FileCache {
  return existsSync(FILE_CACHE) ? (JSON.parse(readFileSync(FILE_CACHE, 'utf8')) as FileCache) : {};
}

function readPhoto(file: string): Buffer {
  const path = join(PHOTOS, file);
  if (!existsSync(path)) throw new Error(`Missing photo ${path}`);
  if (!['.jpg', '.jpeg', '.png'].includes(extname(path).toLowerCase())) {
    throw new Error(`${file}: only .jpg, .jpeg and .png are supported`);
  }
  return readFileSync(path);
}

/** Saves the first raw YouCam response of each kind as a redacted fixture. */
function recordingFetch(apiHost: string): typeof fetch {
  return async (input, init) => {
    const response = await fetch(input, init);
    const url = new URL(String(input instanceof Request ? input.url : input));
    const match = url.pathname.match(/^\/s2s\/v2\.0\/(?:(file)|task\/([a-z0-9-]+)(\/[^/]+)?)$/);
    if (url.host !== apiHost || !match) return response;

    const text = await response.clone().text();
    let name = match[1]
      ? 'file-register'
      : match[3]
        ? `${match[2]}-task-${/"task_status"\s*:\s*"(\w+)"/.exec(text)?.[1] ?? 'unknown'}`
        : `${match[2]}-task-create`;
    if (!response.ok) name += `-http${response.status}`;

    const path = join(FIXTURES, `${name}.json`);
    if (!existsSync(path)) {
      mkdirSync(FIXTURES, { recursive: true });
      writeFileSync(path, redact(text) + '\n');
    }
    return response;
  };
}

/** Removes ids and presigned URL signatures but keeps the response shape. */
function redact(text: string): string {
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    return JSON.stringify({ unparseable: true });
  }
  const walk = (value: unknown, key = ''): unknown => {
    if (Array.isArray(value)) return value.map((item) => walk(item));
    if (value && typeof value === 'object') {
      return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, walk(v, k)]));
    }
    if (typeof value === 'string' && (key === 'file_id' || key === 'task_id')) return 'REDACTED';
    if (typeof value === 'string' && key === 'url') {
      return URL.canParse(value) ? `${new URL(value).origin}/REDACTED` : 'REDACTED';
    }
    return value;
  };
  return JSON.stringify(walk(json), null, 2);
}

function sha256(bytes: Buffer): string {
  return createHash('sha256').update(bytes).digest('hex');
}

function parseArgs(argv: string[]) {
  const get = (name: string) => argv.find((a) => a.startsWith(`--${name}=`))?.split('=')[1];
  const maxUnits = Number(get('max-units') ?? 10);
  if (!Number.isFinite(maxUnits) || maxUnits < 0) throw new Error('--max-units must be a number');
  return {
    run: argv.includes('--run'),
    maxUnits,
    only: get('only')?.split(',') ?? null,
  };
}
