import { createHash } from 'node:crypto';
import type { Repository } from '../data/repository.js';
import type {
  EventRecord,
  FailureReason,
  GarmentCategory,
  ItemRecord,
  LookRecord,
  ParticipantRecord,
  RenderRecord,
  TryOnKind,
} from '../domain/types.js';
import { checkApparelRender, type RenderCheck } from '../harmony/checks.js';
import { decideBudget, summarizeUnits, type LedgerLimits } from '../ledger/ledger.js';
import { mediaPaths, type MediaStorage } from '../storage/storage.js';
import { TryOnStartError, type TryOnInput, type TryOnProvider } from '../youcam/provider.js';

// A look renders as a chain: apparel on the photo, makeup on that result, hair
// on that one. Every step is cached by a content hash of its input image, item
// and parameters, so the same photo with the same item never costs twice.

export interface PipelineDeps {
  repo: Repository;
  storage: MediaStorage;
  /** Provider for real events. */
  provider: TryOnProvider;
  /** Provider for demo events; it never spends units. */
  demoProvider: TryOnProvider;
  limits: LedgerLimits;
  now?: () => number;
  /** Minimum time between two status checks of one live task (docs suggest ~10 s). */
  livePollIntervalMs?: number;
  /** A task still running after this long is marked as timed out. */
  timeoutMs?: number;
}

export type StepStatus = 'pending' | 'running' | 'success' | 'failed';

export interface LookRenderState {
  status: 'no_photo' | 'empty' | 'idle' | 'running' | 'success' | 'failed';
  steps: { kind: TryOnKind; itemId: string; status: StepStatus }[];
  current: TryOnKind | null;
  /** 0..1 over the whole chain. */
  progress: number;
  /** Final image, or the latest finished step while later steps are pending. */
  resultPath: string | null;
  failure: { reason: FailureReason; message: string; retryable: boolean } | null;
  /** True when no real render was made (mock mode or demo illustration). */
  mock: boolean;
  checks: RenderCheck | null;
  /** Units reserved by this look's renders. */
  units: number;
}

/** Failures worth a new attempt (the next call may succeed). */
export const RETRYABLE_REASONS: readonly FailureReason[] = ['provider_error', 'timeout'];
/** Apparel failures after which a seated participant is retried with upper-body framing. */
const SEATED_FALLBACK_REASONS: readonly FailureReason[] = ['pose_not_supported', 'garment_not_applied'];

interface Step {
  kind: TryOnKind;
  item: ItemRecord;
}

export function planSteps(look: LookRecord | null, items: Map<string, ItemRecord>): Step[] {
  if (!look) return [];
  const steps: Step[] = [];
  const add = (kind: TryOnKind, id: string | null) => {
    const item = id ? items.get(id) : undefined;
    if (item) steps.push({ kind, item });
  };
  add('apparel', look.garmentId);
  add('makeup', look.makeupId);
  add('hair', look.hairId);
  return steps;
}

/**
 * Categories to try for an apparel step. The YouCam docs ask for a standing
 * pose; for seated participants a full-body garment falls back to upper-body.
 */
export function apparelCategories(participant: ParticipantRecord, item: ItemRecord): GarmentCategory[] {
  const category = item.category ?? 'full_body';
  return participant.pose === 'seated' && category === 'full_body' ? ['full_body', 'upper_body'] : [category];
}

export function stepHash(inputHash: string, step: Step, category: GarmentCategory | null, mode: string): string {
  const params = step.kind === 'apparel' ? `${step.item.imageHash}|${category}` : step.item.colorHex;
  return createHash('sha256')
    .update(['v1', mode, inputHash, step.kind, step.item.id, params].join('|'))
    .digest('hex');
}

export async function advanceLook(
  deps: PipelineDeps,
  event: EventRecord,
  participant: ParticipantRecord,
  look: LookRecord | null,
  items: Map<string, ItemRecord>,
): Promise<LookRenderState> {
  const provider = event.demo ? deps.demoProvider : deps.provider;
  const mode = event.demo ? 'demo' : provider.mode;
  const now = deps.now ?? Date.now;
  const state: LookRenderState = {
    status: 'idle',
    steps: [],
    current: null,
    progress: 0,
    resultPath: null,
    failure: null,
    mock: event.demo || provider.mode === 'mock',
    checks: null,
    units: 0,
  };
  if (!participant.photoPath || !participant.photoHash) return { ...state, status: 'no_photo' };

  const steps = planSteps(look, items);
  if (steps.length === 0) return { ...state, status: 'empty' };
  state.steps = steps.map((s) => ({ kind: s.kind, itemId: s.item.id, status: 'pending' as StepStatus }));

  let inputPath = participant.photoPath;
  let inputHash = participant.photoHash;

  for (let i = 0; i < steps.length; i++) {
    const step = steps[i]!;
    const categories = step.kind === 'apparel' ? apparelCategories(participant, step.item) : [null];
    let render: RenderRecord | null = null;
    let lastFailed: RenderRecord | null = null;

    for (let c = 0; c < categories.length; c++) {
      const category = categories[c]!;
      const hash = stepHash(inputHash, step, category, mode);
      render = await deps.repo.getRender(event.id, hash);

      if (!render) {
        if (!look?.renderRequested) break;
        const started = await startStep(deps, provider, event, participant, step, category, inputPath, inputHash, hash);
        if ('failure' in started) {
          state.steps[i]!.status = 'failed';
          return { ...state, status: 'failed', current: step.kind, failure: started.failure };
        }
        render = started;
      }
      if (render.status === 'running') render = await pollStep(deps, provider, render, step, category, event, participant);

      const fallbackLeft = c < categories.length - 1;
      if (render.status === 'failed' && fallbackLeft && SEATED_FALLBACK_REASONS.includes(render.failureReason!)) {
        lastFailed = render;
        render = null;
        continue;
      }
      break;
    }

    render ??= lastFailed;
    if (!render) return { ...state, status: 'idle', current: step.kind };

    state.units += render.units;
    if (render.status === 'running') {
      const elapsed = now() - Date.parse(render.createdAt);
      const stepProgress = Math.min(0.95, elapsed / provider.typicalDurationMs);
      state.steps[i]!.status = 'running';
      return { ...state, status: 'running', current: step.kind, progress: (i + stepProgress) / steps.length };
    }
    if (render.status === 'failed') {
      state.steps[i]!.status = 'failed';
      const reason = render.failureReason ?? 'provider_error';
      return {
        ...state,
        status: 'failed',
        current: step.kind,
        failure: { reason, message: render.failureMessage ?? '', retryable: RETRYABLE_REASONS.includes(reason) },
      };
    }

    state.steps[i]!.status = 'success';
    if (step.kind === 'apparel') state.checks = render.checks;
    state.resultPath = render.resultPath;
    inputPath = render.resultPath!;
    inputHash = render.hash;
  }

  return { ...state, status: 'success', progress: 1 };
}

/** Removes the failed render of the current step so the next request tries again. */
export async function resetFailedStep(
  deps: PipelineDeps,
  event: EventRecord,
  participant: ParticipantRecord,
  look: LookRecord | null,
  items: Map<string, ItemRecord>,
): Promise<boolean> {
  const provider = event.demo ? deps.demoProvider : deps.provider;
  const mode = event.demo ? 'demo' : provider.mode;
  if (!participant.photoHash) return false;
  let inputHash = participant.photoHash;
  for (const step of planSteps(look, items)) {
    const categories = step.kind === 'apparel' ? apparelCategories(participant, step.item) : [null];
    let next: RenderRecord | null = null;
    for (const category of categories) {
      const render = await deps.repo.getRender(event.id, stepHash(inputHash, step, category, mode));
      if (!render) return false;
      if (render.status === 'failed') {
        if (!RETRYABLE_REASONS.includes(render.failureReason!)) continue;
        await deps.repo.deleteRender(event.id, render.hash);
        return true;
      }
      next = render;
      break;
    }
    if (!next || next.status !== 'success') return false;
    inputHash = next.hash;
  }
  return false;
}

async function startStep(
  deps: PipelineDeps,
  provider: TryOnProvider,
  event: EventRecord,
  participant: ParticipantRecord,
  step: Step,
  category: GarmentCategory | null,
  inputPath: string,
  inputHash: string,
  hash: string,
): Promise<RenderRecord | { failure: NonNullable<LookRenderState['failure']> }> {
  const cost = provider.cost(step.kind);
  if (cost > 0) {
    const used = summarizeUnits(await deps.repo.listRenders(event.id));
    const decision = decideBudget(
      cost,
      { event: used.event, participant: used.byUser[participant.userId] ?? 0 },
      await provider.balance(),
      deps.limits,
    );
    if (!decision.allowed) {
      return { failure: { reason: 'budget_exhausted', message: decision.message, retryable: false } };
    }
  }

  const timestamp = new Date((deps.now ?? Date.now)()).toISOString();
  const render: RenderRecord = {
    eventId: event.id,
    hash,
    userId: participant.userId,
    kind: step.kind,
    itemId: step.item.id,
    inputPath,
    status: 'running',
    providerTaskId: null,
    resultPath: null,
    failureReason: null,
    failureMessage: null,
    units: cost,
    mock: provider.mode === 'mock',
    checks: null,
    checkedAt: timestamp,
    createdAt: timestamp,
    updatedAt: timestamp,
  };
  // Claim the hash first, so two simultaneous requests never pay for the same render.
  if (!(await deps.repo.insertRenderIfAbsent(render))) {
    return (await deps.repo.getRender(event.id, hash)) ?? render;
  }

  try {
    render.providerTaskId = await provider.start(await loadInput(deps, step, category, inputPath, inputHash));
  } catch (error) {
    render.status = 'failed';
    render.failureReason = error instanceof TryOnStartError ? error.reason : 'provider_error';
    render.failureMessage = error instanceof Error ? error.message : String(error);
    // A task that never started costs nothing.
    render.units = 0;
  }
  render.updatedAt = new Date((deps.now ?? Date.now)()).toISOString();
  await deps.repo.upsertRender(render);
  return render;
}

async function pollStep(
  deps: PipelineDeps,
  provider: TryOnProvider,
  render: RenderRecord,
  step: Step,
  category: GarmentCategory | null,
  event: EventRecord,
  participant: ParticipantRecord,
): Promise<RenderRecord> {
  const now = (deps.now ?? Date.now)();
  const age = now - Date.parse(render.createdAt);
  const fail = async (reason: FailureReason, message: string) => {
    const failed = { ...render, status: 'failed' as const, failureReason: reason, failureMessage: message };
    failed.updatedAt = new Date(now).toISOString();
    await deps.repo.upsertRender(failed);
    return failed;
  };

  if (age > (deps.timeoutMs ?? 6 * 60_000)) return fail('timeout', 'The try-on took too long.');
  // Another request is still starting this task.
  if (!render.providerTaskId) return render;

  const interval = provider.mode === 'mock' ? 0 : (deps.livePollIntervalMs ?? 8000);
  if (render.checkedAt && now - Date.parse(render.checkedAt) < interval) return render;

  let result;
  try {
    result = await provider.check(render.providerTaskId, () => loadInput(deps, step, category, render.inputPath, ''));
  } catch (error) {
    // A failed status check is not a failed render; try again on the next poll.
    console.error('try-on status check failed', error);
    return render;
  }

  const updated: RenderRecord = { ...render, checkedAt: new Date(now).toISOString(), updatedAt: new Date(now).toISOString() };
  if (result.state === 'running') {
    await deps.repo.upsertRender(updated);
    return updated;
  }
  if (result.state === 'failed') return fail(result.reason, result.message);

  const resultPath = mediaPaths.render(event.id, participant.userId, render.hash);
  await deps.storage.put(resultPath, result.image, 'image/jpeg');
  updated.status = 'success';
  updated.resultPath = resultPath;
  if (step.kind === 'apparel') {
    const photo = await deps.storage.get(render.inputPath);
    if (photo) updated.checks = await checkApparelRender(photo, result.image, step.item.dominantColors);
  }
  await deps.repo.upsertRender(updated);
  return updated;
}

async function loadInput(
  deps: PipelineDeps,
  step: Step,
  category: GarmentCategory | null,
  inputPath: string,
  inputHash: string,
): Promise<TryOnInput> {
  const image = await deps.storage.get(inputPath);
  if (!image) throw new TryOnStartError('image_invalid', null, 'The photo for this try-on is missing.');
  const input: TryOnInput = { kind: step.kind, image, imageHash: inputHash || hashOf(image) };

  if (step.kind === 'apparel') {
    const garment = step.item.imagePath ? await deps.storage.get(step.item.imagePath) : null;
    if (!garment) throw new TryOnStartError('image_invalid', null, 'This garment has no image yet.');
    input.garment = {
      image: garment,
      hash: step.item.imageHash ?? hashOf(garment),
      category: category ?? 'full_body',
      colorHex: step.item.dominantColors?.[0]?.hex ?? null,
    };
    // Only the mock provider reads this; it lets tests and demos show the failure path.
    input.simulateFailure = step.item.name.toLowerCase().startsWith('mock-fail');
  } else {
    input.colorHex = step.item.colorHex ?? '#000000';
  }
  return input;
}

const hashOf = (bytes: Buffer) => createHash('sha256').update(bytes).digest('hex');
