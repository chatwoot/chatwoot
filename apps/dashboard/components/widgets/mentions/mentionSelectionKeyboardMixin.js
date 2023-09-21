import { buildHotKeys } from 'shared/helpers/KeyboardHelpers';

export default {
  mounted() {
    document.addEventListener('keydown', this.handleKeyboardEvent);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleKeyboardEvent);
  },
  methods: {
    moveSelectionUp() {
      if (!this.selectedIndex) {
        this.selectedIndex = this.items.length - 1;
      } else {
        this.selectedIndex -= 1;
      }
    },
    moveSelectionDown() {
      if (this.selectedIndex === this.items.length - 1) {
        this.selectedIndex = 0;
      } else {
        this.selectedIndex += 1;
      }
    },
    processKeyDownEvent(e) {
      const keyPattern = buildHotKeys(e);
      if (['arrowup', 'ctrl+p'].includes(keyPattern)) {
        this.moveSelectionUp();
        e.preventDefault();
      } else if (['arrowdown', 'ctrl+n'].includes(keyPattern)) {
        this.moveSelectionDown();
        e.preventDefault();
      } else if (keyPattern === 'enter') {
        this.onSelect();
        e.preventDefault();
      }
    },
  },
};
