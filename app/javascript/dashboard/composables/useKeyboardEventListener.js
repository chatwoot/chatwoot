import { onMounted, onBeforeUnmount } from 'vue';
import { isActiveElementTypeable, isEscape } from '../helpers/KeyboardHelpers';
import { createKeybindingsHandler } from 'tinykeys';

// Store that stores the handler globally, and only gets reset on reload
const taggedHandlers = [];

/**
 * Composable for handling keyboard event listeners.
 * @returns {Object} An object containing methods for managing keyboard event listeners.
 */
export function useKeyboardEventListener() {
  let handlerIndex = -1;

  const wrapEventsInKeybindingsHandler = events => {
    const wrappedEvents = {};
    Object.keys(events).forEach(eventName => {
      wrappedEvents[eventName] = keydownWrapper(events[eventName]);
    });
    return wrappedEvents;
  };

  const keydownWrapper = handler => {
    return e => {
      const actionToPerform =
        typeof handler === 'function' ? handler : handler.action;
      const allowOnFocusedInput =
        typeof handler === 'function' ? false : handler.allowOnFocusedInput;

      const isTypeable = isActiveElementTypeable(e);

      if (isTypeable) {
        if (isEscape(e)) {
          e.target.blur();
        }

        if (!allowOnFocusedInput) return;
      }

      actionToPerform(e);
    };
  };

  const addEventHandler = events => {
    const wrappedEvents = wrapEventsInKeybindingsHandler(events);
    const keydownHandler = createKeybindingsHandler(wrappedEvents);
    handlerIndex = taggedHandlers.push(keydownHandler) - 1;
    document.addEventListener('keydown', keydownHandler);
  };

  const removeEventHandler = () => {
    if (handlerIndex !== -1) {
      const handlerToRemove = taggedHandlers[handlerIndex];
      document.removeEventListener('keydown', handlerToRemove);
      handlerIndex = -1;
    }
  };

  onBeforeUnmount(() => {
    removeEventHandler();
  });

  return {
    addEventHandler,
    removeEventHandler,
  };
}
