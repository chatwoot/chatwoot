import {
  isActiveElementTypeable,
  isEscape,
  keysToModifyInQWERTZ,
  LAYOUT_QWERTZ,
} from 'shared/helpers/KeyboardHelpers';
import { useDetectKeyboardLayout } from 'dashboard/composables/useDetectKeyboardLayout';
import { createKeybindingsHandler } from 'tinykeys';
import { onUnmounted, onMounted } from 'vue';

/**
 * Determines if the keyboard event should be ignored based on the element type and handler settings.
 * @param {Event} e - The event object.
 * @param {Object|Function} handler - The handler configuration or function.
 * @returns {boolean} - True if the event should be ignored, false otherwise.
 */
const shouldIgnoreEvent = (e, handler) => {
  const isTypeable = isActiveElementTypeable(e);
  const allowOnFocusedInput =
    typeof handler === 'function' ? false : handler.allowOnFocusedInput;

  if (isTypeable) {
    if (isEscape(e)) {
      e.target.blur();
    }
    return !allowOnFocusedInput;
  }
  return false;
};

/**
 * Wraps the event handler to include custom logic before executing the handler.
 * @param {Function} handler - The original event handler.
 * @returns {Function} - The wrapped handler.
 */
const keydownWrapper = handler => {
  return e => {
    if (shouldIgnoreEvent(e, handler)) return;
    //  extract the action to perform from the handler

    const actionToPerform =
      typeof handler === 'function' ? handler : handler.action;
    actionToPerform(e);
  };
};

/**
 * Wraps all provided keyboard events in handlers that respect the current keyboard layout.
 * @param {Object} events - The object containing event names and their handlers.
 * @returns {Object} - The object with event names possibly modified based on the keyboard layout and wrapped handlers.
 */
async function wrapEventsInKeybindingsHandler(events) {
  const wrappedEvents = {};
  const currentLayout = await useDetectKeyboardLayout();

  Object.keys(events).forEach(originalEventName => {
    const modifiedEventName =
      currentLayout === LAYOUT_QWERTZ &&
      keysToModifyInQWERTZ.has(originalEventName)
        ? `Shift+${originalEventName}`
        : originalEventName;

    wrappedEvents[modifiedEventName] = keydownWrapper(
      events[originalEventName]
    );
  });
  return wrappedEvents;
}

/**
 * Vue composable to handle keyboard events with support for different keyboard layouts.
 * @param {Object} keyboardEvents - The keyboard events to handle.
 */
export async function useKeyboardEvents(keyboardEvents) {
  let abortController = new AbortController();

  onMounted(async () => {
    if (!keyboardEvents) return;
    const wrappedEvents = await wrapEventsInKeybindingsHandler(keyboardEvents);
    const keydownHandler = createKeybindingsHandler(wrappedEvents);

    document.addEventListener('keydown', keydownHandler, {
      signal: abortController.signal,
    });
  });

  onUnmounted(() => {
    abortController.abort();
  });
}
