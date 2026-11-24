import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CAPTAIN_ERROR_TYPES } from 'dashboard/composables/captain/constants';

export const REPLY_SUGGESTION_TIMEOUT_MS = 90000;
export const REPLY_SUGGESTION_TIMEOUT_ERROR = 'ReplySuggestionTimeout';
export const REPLY_SUGGESTION_DISCONNECTED_ERROR =
  'ReplySuggestionDisconnected';

const namedError = name => {
  const error = new Error(name);
  error.name = name;
  return error;
};

/**
 * Waits for the reply suggestion a background job sends over the live connection.
 * Only the result for this request and conversation counts. A cancelled request, a lost connection
 * or a timeout ends the wait, so the reply box never waits forever.
 * @param {Object} options
 * @param {string} options.requestId - The ID the server returned for this request.
 * @param {number} options.conversationId - The conversation the draft was asked for.
 * @param {AbortSignal} [options.signal] - Aborted when the agent cancels or leaves the conversation.
 * @param {number} [options.timeoutMs] - How long to wait.
 * @returns {Promise<Object>} The event data.
 */
export function waitForReplySuggestion({
  requestId,
  conversationId,
  signal,
  timeoutMs = REPLY_SUGGESTION_TIMEOUT_MS,
}) {
  return new Promise((resolve, reject) => {
    let timeoutId;
    let onResponse;
    let onDisconnect;
    let onAbort;

    const finish = () => {
      clearTimeout(timeoutId);
      emitter.off(BUS_EVENTS.CAPTAIN_REPLY_SUGGESTION_READY, onResponse);
      emitter.off(BUS_EVENTS.WEBSOCKET_DISCONNECT, onDisconnect);
      signal?.removeEventListener('abort', onAbort);
    };

    onResponse = data => {
      if (data.request_id !== requestId) return;
      if (data.conversation_id !== conversationId) return;

      finish();
      resolve(data);
    };
    onDisconnect = () => {
      finish();
      reject(namedError(REPLY_SUGGESTION_DISCONNECTED_ERROR));
    };
    onAbort = () => {
      finish();
      reject(namedError(CAPTAIN_ERROR_TYPES.ABORT_ERROR));
    };

    if (signal?.aborted) {
      reject(namedError(CAPTAIN_ERROR_TYPES.ABORT_ERROR));
      return;
    }

    emitter.on(BUS_EVENTS.CAPTAIN_REPLY_SUGGESTION_READY, onResponse);
    emitter.on(BUS_EVENTS.WEBSOCKET_DISCONNECT, onDisconnect);
    signal?.addEventListener('abort', onAbort);
    timeoutId = setTimeout(() => {
      finish();
      reject(namedError(REPLY_SUGGESTION_TIMEOUT_ERROR));
    }, timeoutMs);
  });
}
