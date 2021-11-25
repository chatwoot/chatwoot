import { isEscape } from '../helpers/KeyboardHelpers';

export default {
  mounted() {
    document.addEventListener('keydown', this.onKeyDownHandler);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.onKeyDownHandler);
  },
  methods: {
    onKeyDownHandler(e) {
      const isEventFromAnInputBox =
        e.target?.tagName === 'INPUT' || e.target?.tagName === 'TEXTAREA';
      const isEventFromProseMirror = e.target?.className?.includes(
        'ProseMirror'
      );

      if (isEventFromAnInputBox || isEventFromProseMirror) {
        if (isEscape(e)) {
          e.target.blur();
        }
        return;
      }

      this.handleKeyEvents(e);
    },
  },
};
