import { PlanEvent, TrackPlan } from '../core/events/interfaces'

/**
 * Determines whether a track event is allowed to be sent based on the
 * user's tracking plan.
 * If the user does not have a tracking plan or the event is allowed based
 * on the tracking plan configuration, returns true.
 */
export function isPlanEventEnabled(
  plan: TrackPlan | undefined,
  planEvent: PlanEvent | undefined
): boolean {
  // Always prioritize the event's `enabled` status
  if (typeof planEvent?.enabled === 'boolean') {
    return planEvent.enabled
  }

  // Assume absence of a tracking plan means events are enabled
  return plan?.__default?.enabled ?? true
}
