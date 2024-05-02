/* eslint-disable no-console */
import { isActiveElementTypeable, isEscape } from '../helpers/KeyboardHelpers';

import { createKeybindingsHandler } from 'shared/helpers/keybindings';
import * as Sentry from '@sentry/browser';

// this is a store that stores the handler globally, and only gets reset on reload
const taggedHandlers = [];

export default {
  mounted() {
    const events = this.getKeyboardEvents();
    if (events) {
      const wrappedEvents = this.wrapEventsInKeybindingsHandler(events);
      const keydownHandler = createKeybindingsHandler(wrappedEvents);
      this.addEventHandler(keydownHandler);
    }
  },
  beforeDestroy() {
    if (this.$el && this.$el.dataset?.keydownHandlerIndex) {
      const handlerToRemove =
        taggedHandlers[this.$el.dataset.keydownHandlerIndex];
      document.removeEventListener('keydown', handlerToRemove);
    }
  },
  methods: {
    addEventHandler(keydownHandler) {
      const indexToAppend = taggedHandlers.push(keydownHandler) - 1;
      const root = this.$el;
      if (root && root.dataset) {
        // For the components with a top level v-if Vue renders it as an empty comment in the DOM
        // so we need to check if the root element has a dataset property to ensure it is a valid element
        document.addEventListener('keydown', keydownHandler);
        root.dataset.keydownHandlerIndex = indexToAppend;
      }
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
        const isFunction = typeof handler === 'function';
        const actionToPerform = isFunction ? handler : handler.action;
        const allowOnFocusedInput = isFunction
          ? false
          : handler.allowOnFocusedInput;

        try {
          const isTypeable = isActiveElementTypeable(e);

          if (isTypeable) {
            if (isEscape(e)) e.target.blur();
            console.log('isTypeable', isTypeable);
            console.log('allowOnFocusedInput', allowOnFocusedInput);
            if (!allowOnFocusedInput) return;
          }

          actionToPerform(e);
        } catch (err) {
          // ignore errors
          Sentry.captureException(err, {
            context: {
              component: this.$options?.name,
              isFunction: isFunction,
              allowOnFocusedInput: allowOnFocusedInput,
            },
          });
        }
      };
    },
  },
};
