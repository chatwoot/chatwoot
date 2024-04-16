import {
  isActiveElementTypeable,
  isEscape,
  buildHotKeys,
} from '../helpers/KeyboardHelpers';

export default {
  mounted() {
    document.addEventListener('keydown', this.onKeyDownHandler);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.onKeyDownHandler);
  },
  methods: {
    onKeyDownHandler(e) {
      const isTypeable = isActiveElementTypeable(e);

      if (isTypeable) {
        if (isEscape(e)) {
          e.target.blur();
        }

        const hasPressedCommandPlusAltAndEKey =
          buildHotKeys(e) === 'alt+meta+e';

        // Added this to blur the input field when the user presses Command + Option + E (Mac) or Ctrl + Alt + E (Windows)
        // Only case for Resolve conversation and open next conversation in the list
        if (!hasPressedCommandPlusAltAndEKey) {
          return;
        }
        e.target.blur();
      }

      this.handleKeyEvents(e);
    },
  },
};
