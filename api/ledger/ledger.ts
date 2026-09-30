import type { RenderRecord } from '../domain/types.js';

export interface LedgerLimits {
  perEvent: number;
  perParticipant: number;
  /** Units to keep on the account no matter what. */
  accountReserve: number;
}

export interface UnitSummary {
  event: number;
  byUser: Record<string, number>;
}

export type BudgetDecision =
  | { allowed: true }
  | { allowed: false; scope: 'event' | 'participant' | 'account'; message: string };

export function summarizeUnits(renders: RenderRecord[]): UnitSummary {
  const byUser: Record<string, number> = {};
  let event = 0;
  for (const render of renders) {
    event += render.units;
    byUser[render.userId] = (byUser[render.userId] ?? 0) + render.units;
  }
  return { event: round2(event), byUser };
}

/**
 * Decides whether one more call of `cost` units is allowed. Checked before every
 * paid call: event cap, participant cap, then the live account balance.
 */
export function decideBudget(
  cost: number,
  used: { event: number; participant: number },
  balance: number | null,
  limits: LedgerLimits,
): BudgetDecision {
  if (cost <= 0) return { allowed: true };
  if (used.event + cost > limits.perEvent) {
    return { allowed: false, scope: 'event', message: `This event has used its render budget (${limits.perEvent} units).` };
  }
  if (used.participant + cost > limits.perParticipant) {
    return {
      allowed: false,
      scope: 'participant',
      message: `You have used your render budget for this event (${limits.perParticipant} units).`,
    };
  }
  if (balance !== null && balance - cost < limits.accountReserve) {
    return { allowed: false, scope: 'account', message: 'The try-on service has no units left right now.' };
  }
  return { allowed: true };
}

const round2 = (value: number) => Math.round(value * 100) / 100;
