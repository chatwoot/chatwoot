import { emitter } from 'shared/helpers/mitt';
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
