import { isEscape } from '../helpers/KeyboardHelpers';

export default {
  mounted() {
    document.addEventListener('keydown', e => {
      const isEventFromAnInputBox = e.target?.tagName === 'INPUT';
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
    });
  },
  destroyed() {
    document.removeEventListener('keydown', this.handleKeyEvents);
  },
};
