<template>
  <ul
    ref="dropdownMenu"
    class="dropdown menu vertical"
    :class="[placement && `dropdown--${placement}`]"
  >
    <slot />
  </ul>
</template>
<script>
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
export default {
  name: 'WootDropdownMenu',
  componentName: 'WootDropdownMenu',

  mixins: [keyboardEventListenerMixins],

  props: {
    placement: {
      type: String,
      default: 'top',
    },
  },
  methods: {
    dropdownMenuButtons() {
      return this.$refs.dropdownMenu.querySelectorAll(
        'ul.dropdown li.dropdown-menu__item .button'
      );
    },
    getActiveButtonIndex(menuButtons) {
      const focusedButton = this.$refs.dropdownMenu.querySelector(
        'ul.dropdown li.dropdown-menu__item .button:focus'
      );
      return Array.from(menuButtons).indexOf(focusedButton);
    },
    getKeyboardEvents() {
      const menuButtons = this.dropdownMenuButtons();
      return {
        ArrowUp: () => this.focusPreviousButton(menuButtons),
        ArrowDown: () => this.focusNextButton(menuButtons),
      };
    },
    focusPreviousButton(menuButtons) {
      const activeIndex = this.getActiveButtonIndex(menuButtons);
      const newIndex =
        activeIndex >= 1 ? activeIndex - 1 : menuButtons.length - 1;
      this.focusButton(menuButtons, newIndex);
    },
    focusNextButton(menuButtons) {
      const activeIndex = this.getActiveButtonIndex(menuButtons);
      const newIndex =
        activeIndex === menuButtons.length - 1 ? 0 : activeIndex + 1;
      this.focusButton(menuButtons, newIndex);
    },
    focusButton(menuButtons, newIndex) {
      if (menuButtons.length === 0) return;
      menuButtons[newIndex].focus();
    },
  },
};
</script>
