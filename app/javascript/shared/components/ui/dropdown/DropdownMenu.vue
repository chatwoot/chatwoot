<template>
  <ul
    ref="dropdownMenu"
    class="dropdown menu vertical"
    :class="[placement && `dropdown--${placement}`]"
  >
    <slot></slot>
  </ul>
</template>
<script>
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import {
  hasPressedArrowUpKey,
  hasPressedArrowDownKey,
} from 'shared/helpers/KeyboardHelpers';
export default {
  name: 'WootDropdownMenu',
  componentName: 'WootDropdownMenu',

  mixins: [eventListenerMixins],

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
    activeElementIndex() {
      const menuButtons = this.dropdownMenuButtons();
      const focusedButton = this.$refs.dropdownMenu.querySelector(
        'ul.dropdown li.dropdown-menu__item .button:focus'
      );
      const activeIndex = [...menuButtons].indexOf(focusedButton);
      return activeIndex;
    },
    handleKeyEvents(e) {
      const menuButtons = this.dropdownMenuButtons();
      const lastElementIndex = menuButtons.length - 1;

      if (menuButtons.length === 0) return;

      if (hasPressedArrowUpKey(e)) {
        const activeIndex = this.activeElementIndex();

        if (activeIndex >= 1) {
          menuButtons[activeIndex - 1].focus();
        } else {
          menuButtons[lastElementIndex].focus();
        }
      }
      if (hasPressedArrowDownKey(e)) {
        const activeIndex = this.activeElementIndex();

        if (activeIndex === lastElementIndex) {
          menuButtons[0].focus();
        } else {
          menuButtons[activeIndex + 1].focus();
        }
      }
    },
  },
};
</script>
