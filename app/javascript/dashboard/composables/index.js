import { getCurrentInstance } from 'vue';
import { emitter } from 'shared/helpers/mitt';

/**
 * Custom hook to track events
 * @returns {Function} The track function
 */
export const useTrack = () => {
  const vm = getCurrentInstance();
  if (!vm) throw new Error('must be called in setup');

  return vm.proxy.$track;
};

/**
 * Emits a toast message event using a global emitter.
 * @param {string} message - The message to be displayed in the toast.
 * @param {Object|null} action - Optional callback function or object to execute.
 */
export const useAlert = (message, action = null) => {
  emitter.emit('newToastMessage', { message, action });
};
