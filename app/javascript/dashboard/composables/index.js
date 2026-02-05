import { emitter } from 'shared/helpers/mitt';
import { track as outlitTrack, user as outlitUser } from '@outlit/browser';
import analyticsHelper from 'dashboard/helper/AnalyticsHelper/index';
import { toSnakeCase } from 'shared/helpers/outlitHelper';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

/**
 * Custom hook to track events
 */
export const useTrack = (eventName, properties = {}) => {
  try {
    analyticsHelper.track(eventName, properties);
  } catch (error) {
    // Ignore this, tracking is not mission critical
  }

  try {
    outlitTrack(toSnakeCase(eventName), properties);
    if (eventName === CONVERSATION_EVENTS.SENT_MESSAGE) {
      outlitUser().activate({ channelType: properties.channelType });
    }
  } catch (error) {
    // Outlit not initialized — ignore
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
