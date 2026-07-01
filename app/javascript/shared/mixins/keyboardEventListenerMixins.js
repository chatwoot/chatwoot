import { isActiveElementTypeable, isEscape } from '../helpers/KeyboardHelpers';

import { createKeybindingsHandler } from 'tinykeys';

export default {
  mounted() {
    const events = this.getKeyboardEvents();
    if (events) {
      const wrappedEvents = this.wrapEventsInKeybindingsHandler(events);
      const keydownHandler = createKeybindingsHandler(wrappedEvents);
      this.addEventHandler(keydownHandler);
    }
  },
  unmounted() {
    if (this.keydownHandlerRef) {
      document.removeEventListener('keydown', this.keydownHandlerRef);
      this.keydownHandlerRef = null;
    }
  },
  methods: {
    addEventHandler(keydownHandler) {
      const root = this.getElementToBind();
      if (root && root.dataset) {
        // For the components with a top level v-if Vue renders it as an empty comment in the DOM
        // so we need to check if the root element has a dataset property to ensure it is a valid element
        // Keep the exact handler on the instance so unmounted() can remove it. Using $el.dataset here
        // is unreliable for multi-root (fragment) components where $el is a comment anchor without dataset.
        document.addEventListener('keydown', keydownHandler);
        this.keydownHandlerRef = keydownHandler;
      }
    },
    getElementToBind() {
      return this.$el;
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
