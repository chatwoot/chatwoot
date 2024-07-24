import { onMounted, onBeforeUnmount } from 'vue';
import {
  isActiveElementTypeable,
  isEscape,
} from 'shared/helpers/KeyboardHelpers';
import { createKeybindingsHandler } from 'tinykeys';

const addKeydownHandler = (keydownHandler, elRef, taggedHandlers) => {
  const root = elRef?.value;
  document.addEventListener('keydown', keydownHandler);
  taggedHandlers.set(root, keydownHandler);
};

// Helper function to determine if the event should be ignored based on the type of element and handler settings
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

const keydownWrapper = handler => {
  return e => {
    if (shouldIgnoreEvent(e, handler)) return;
    //  extract the action to perform from the handler

    const actionToPerform =
      typeof handler === 'function' ? handler : handler.action;
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

const setupListeners = (elRef, getKeyboardEvents, addEventHandler) => {
  const events = getKeyboardEvents();
  const root = elRef?.value;
  if (!(root instanceof Element)) {
    return;
  }
  if (events) {
    const wrappedEvents = wrapEventsInKeybindingsHandler(events);
    const keydownHandler = createKeybindingsHandler(wrappedEvents);
    addEventHandler(keydownHandler);
  }
};

const removeListeners = (elRef, taggedHandlers) => {
  const root = elRef?.value;
  if (root instanceof Element && taggedHandlers.has(root)) {
    const handlerToRemove = taggedHandlers.get(root);
    document.removeEventListener('keydown', handlerToRemove);
  }
};

export function useKeyboardEvents(keyboardEvents, elRef = null) {
  // this is a store that stores the handler globally, and only gets reset on reload
  const taggedHandlers = new WeakMap();

  const getKeyboardEvents = () => keyboardEvents || null;
  const addEventHandler = keydownHandler =>
    addKeydownHandler(keydownHandler, elRef, taggedHandlers);
  const setupEventListeners = () =>
    setupListeners(elRef, getKeyboardEvents, addEventHandler);
  const removeEventListeners = () => removeListeners(elRef, taggedHandlers);

  onMounted(setupEventListeners);
  onBeforeUnmount(removeEventListeners);

  return { getKeyboardEvents };
}
