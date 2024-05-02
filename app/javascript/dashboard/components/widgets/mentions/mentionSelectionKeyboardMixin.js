import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';

export default {
  mixins: [keyboardEventListenerMixins],
  methods: {
    moveSelectionUp() {
      if (!this.selectedIndex) {
        this.selectedIndex = this.items.length - 1;
      } else {
        this.selectedIndex -= 1;
      }
      this.adjustScroll();
    },
    moveSelectionDown() {
      if (this.selectedIndex === this.items.length - 1) {
        this.selectedIndex = 0;
      } else {
        this.selectedIndex += 1;
      }
      this.adjustScroll();
    },
    getKeyboardEvents() {
      return {
        ArrowUp: {
          action: this.moveSelectionUp,
          allowOnFocusedInput: true,
        },
        'Control+KeyP': {
          action: e => {
            this.moveSelectionUp();
            e.preventDefault();
          },
          allowOnFocusedInput: true,
        },
        ArrowDown: {
          action: this.moveSelectionDown,
          allowOnFocusedInput: true,
        },
        'Control+KeyN': {
          action: e => {
            this.moveSelectionDown();
            e.preventDefault();
          },
          allowOnFocusedInput: true,
        },
        Enter: {
          action: e => {
            this.onSelect();
            e.preventDefault();
          },
          allowOnFocusedInput: true,
        },
      };
    },
  },
};
