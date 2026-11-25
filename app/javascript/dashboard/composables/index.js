import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import analyticsHelper from 'dashboard/helper/AnalyticsHelper/index';

/**
 * Custom hook to track events
 */
export const useTrack = (...args) => {
  try {
    return analyticsHelper.track(...args);
  } catch (error) {
    // Ignore this, tracking is not mission critical
  }

  return null;
};

/**
 * Emits a toast message event using a global emitter.
 * @param {string} message - The message to be displayed in the toast.
 * @param {Object|null} action - Optional callback function or object to execute.
 */
export const useAlert = (message, action = null) => {
  emitter.emit('newToastMessage', { message, action });
};

let pendingAlertCounter = 0;

/**
 * Shows a persistent toast that stays visible until explicitly dismissed.
 * Useful for long-running operations (e.g. "Adding member...").
 * @param {string} message - The message to display while the operation is in progress.
 * @returns {Function} dismiss - Call this function to remove the persistent toast.
 */
export const usePendingAlert = message => {
  pendingAlertCounter += 1;
  const key = `pending-${Date.now()}-${pendingAlertCounter}`;
  emitter.emit('newToastMessage', {
    message,
    action: { persistent: true, key },
  });
  return () => emitter.emit('dismissToastMessage', { key });
};

/**
 * Reports a conversation action that the server refused.
 *
 * A 409 means an inbox with `prevent_assignment_takeover` would not move the
 * conversation away from the agent handling it, which can come from assigning
 * an agent, from picking a team that excludes the current one, or from
 * reopening. It also means an inbox with `restrict_assignment_to_working_hours`
 * is closed, which the response tells apart with `reason`. It gets a dialog rather than a toast: the toast fades on its own
 * and the agent is about to start working a conversation that is not theirs.
 * Anything else falls back to the caller's own message.
 * @param {Object} error - The rejected axios error.
 * @param {string} fallbackMessage - Toast shown when it is not a conflict.
 */
export const useAssignmentError = (error, fallbackMessage) => {
  if (error?.response?.status !== 409) {
    useAlert(fallbackMessage);
    return;
  }

  emitter.emit(BUS_EVENTS.ASSIGNMENT_CONFLICT, {
    agentName: error.response.data?.agent_name ?? '',
    reason: error.response.data?.reason ?? '',
  });
};
