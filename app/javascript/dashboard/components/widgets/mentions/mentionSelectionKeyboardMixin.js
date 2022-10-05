import { buildHotKeys } from 'shared/helpers/KeyboardHelpers';

export default {
  mounted() {
    document.addEventListener('keydown', this.handleKeyboardEvent);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleKeyboardEvent);
  },
  methods: {
    processKeyDownEvent(e) {
      const keyPattern = buildHotKeys(e);
      if (['arrowup', 'ctrl+p'].includes(keyPattern)) {
        if (!this.selectedIndex) {
          this.selectedIndex = this.items.length - 1;
        } else {
          this.selectedIndex -= 1;
        }
        e.preventDefault();
      } else if (['arrowdown', 'ctrl+n'].includes(keyPattern)) {
        if (this.selectedIndex === this.items.length - 1) {
          this.selectedIndex = 0;
        } else {
          this.selectedIndex += 1;
        }
        e.preventDefault();
      } else if (keyPattern === 'enter') {
        this.onSelect();
        e.preventDefault();
      }
    },
  },
};
