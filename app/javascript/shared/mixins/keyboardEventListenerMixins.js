import { isActiveElementTypeable, isEscape } from '../helpers/KeyboardHelpers';

import { createKeybindingsHandler } from 'tinykeys';

// this is a store that stores the handler globally, and only gets reset on reload
const taggedHandlers = [];

export default {
  mounted() {
    const events = this.getKeyboardEvents();
    if (events) {
      const wrappedEvents = this.wrapEventsInKeybindingsHandler(events);
      const keydownHandler = createKeybindingsHandler(wrappedEvents);
      this.appendToHandler(keydownHandler);
      document.addEventListener('keydown', keydownHandler);
    }
  },
  beforeDestroy() {
    if (this.$el && this.$el.dataset.keydownHandlerIndex) {
      const handlerToRemove =
        taggedHandlers[this.$el.dataset.keydownHandlerIndex];
      document.removeEventListener('keydown', handlerToRemove);
    }
  },
  methods: {
    appendToHandler(keydownHandler) {
      const indexToAppend = taggedHandlers.push(keydownHandler) - 1;
      const root = this.$el;
      root.dataset.keydownHandlerIndex = indexToAppend;
    },
    getKeyboardEvents() {
      return null;
    },
    wrapEventsInKeybindingsHandler(events) {
      const wrappedEvents = {};
      Object.keys(events).forEach(eventName => {
        wrappedEvents[eventName] = this.keydownWrapper(events[eventName]);
      });

      return wrappedEvents;
    },
    keydownWrapper(handler) {
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
    },
  },
};
