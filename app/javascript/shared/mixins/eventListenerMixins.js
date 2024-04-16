import { isActiveElementTypeable, isEscape } from '../helpers/KeyboardHelpers';

import { createKeybindingsHandler } from 'tinykeys';

export default {
  data() {
    return {
      keyboardHandler: null,
    };
  },
  mounted() {
    const events = this.getKeyboardEvents();
    if (events) {
      const wrappedEvents = this.wrapEventsInKeybindingsHandler(events);
      this.keyboardHandler = createKeybindingsHandler(wrappedEvents);
      document.addEventListener('keydown', this.keyboardHandler);
    }
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.keyboardHandler);
  },
  methods: {
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
        const isTypeable = isActiveElementTypeable(e);

        if (isTypeable) {
          if (isEscape(e)) {
            e.target.blur();
          }
          return;
        }

        handler(e);
      };
    },
  },
};
