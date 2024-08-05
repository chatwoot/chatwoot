import { onMounted, onBeforeUnmount, unref } from 'vue';
import {
  isActiveElementTypeable,
  isEscape,
  keysToModifyInQWERTZ,
  LAYOUT_QWERTZ,
} from 'shared/helpers/KeyboardHelpers';
import { useDetectKeyboardLayout } from 'dashboard/composables/useDetectKeyboardLayout';
import { createKeybindingsHandler } from 'tinykeys';

const keyboardListenerMap = new WeakMap();

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
 * Sets up keyboard event listeners on the specified element.
 * @param {Element} root - The DOM element to attach listeners to.
 * @param {Object} events - The events to listen for.
 */
const setupListeners = (root, events) => {
  if (root instanceof Element && events) {
    const keydownHandler = createKeybindingsHandler(events);
    const handler = window.addEventListener('keydown', keydownHandler);
    keyboardListenerMap.set(root, handler);
  }
};

/**
 * Removes keyboard event listeners from the specified element.
 * @param {Element} root - The DOM element to remove listeners from.
 */
const removeListeners = root => {
  if (root instanceof Element) {
    const handlerToRemove = keyboardListenerMap.get(root);
    document.removeEventListener('keydown', handlerToRemove);
    keyboardListenerMap.delete(root);
  }
};

/**
 * Vue composable to handle keyboard events with support for different keyboard layouts.
 * @param {Object} keyboardEvents - The keyboard events to handle.
 * @param {ref} elRef - A Vue ref to the element to attach the keyboard events to.
 */
export function useKeyboardEvents(keyboardEvents, elRef = null) {
  onMounted(async () => {
    const el = unref(elRef);
    const getKeyboardEvents = () => keyboardEvents || null;
    const events = getKeyboardEvents();
    const wrappedEvents = await wrapEventsInKeybindingsHandler(events);
    setupListeners(el, wrappedEvents);
  });

  onBeforeUnmount(() => {
    const el = unref(elRef);
    removeListeners(el);
  });
}
