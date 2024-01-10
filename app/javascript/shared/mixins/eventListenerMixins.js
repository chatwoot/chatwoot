import { isActiveElementTypeable, isEscape } from '../helpers/KeyboardHelpers';

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
        return;
      }

      this.handleKeyEvents(e);
    },
  },
};
