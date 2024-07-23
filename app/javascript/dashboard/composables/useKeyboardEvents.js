import { onMounted, onBeforeUnmount } from 'vue';
import {
  isActiveElementTypeable,
  isEscape,
} from 'shared/helpers/KeyboardHelpers';
import { createKeybindingsHandler } from 'tinykeys';

export function useKeyboardEvents(elRef, keyboardEvents) {
  // this is a store that stores the handler globally, and only gets reset on reload
  const taggedHandlers = [];

  const getKeyboardEvents = () => {
    // Define your keyboard events here
    return keyboardEvents || null;
  };

  const addEventHandler = keydownHandler => {
    const indexToAppend = taggedHandlers.push(keydownHandler) - 1;
    const root = elRef.value;
    console.log('rootel', root);
    if (root && root.dataset) {
      // For the components with a top level v-if Vue renders it as an empty comment in the DOM
      // so we need to check if the root element has a dataset property to ensure it is a valid element
      document.addEventListener('keydown', keydownHandler);
      root.dataset.keydownHandlerIndex = indexToAppend;
    }
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

  const wrapEventsInKeybindingsHandler = events => {
    const wrappedEvents = {};
    Object.keys(events).forEach(eventName => {
      wrappedEvents[eventName] = keydownWrapper(events[eventName]);
    });
    return wrappedEvents;
  };

  onMounted(() => {
    console.log('mounted');
    const events = getKeyboardEvents();
    console.log(events);

    if (events) {
      const wrappedEvents = wrapEventsInKeybindingsHandler(events);
      const keydownHandler = createKeybindingsHandler(wrappedEvents);
      addEventHandler(keydownHandler);
    }
  });

  onBeforeUnmount(() => {
    if (elRef.value && elRef.value.dataset?.keydownHandlerIndex) {
      const handlerToRemove =
        taggedHandlers[elRef.value.dataset.keydownHandlerIndex];
      document.removeEventListener('keydown', handlerToRemove);
    }
  });

  return {
    getKeyboardEvents,
  };
}
