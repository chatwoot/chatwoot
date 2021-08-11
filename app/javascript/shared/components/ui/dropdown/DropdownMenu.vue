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

  mounted() {
    this.focusItem();
  },
  methods: {
    focusItem() {
      this.$refs.dropdownMenu
        .querySelector('ul.dropdown li.dropdown-menu__item .button')
        .focus();
    },
    handleKeyEvents(e) {
      if (hasPressedArrowUpKey(e)) {
        const items = this.$refs.dropdownMenu.querySelectorAll(
          'ul.dropdown li.dropdown-menu__item .button'
        );
        const focusItems = this.$refs.dropdownMenu.querySelector(
          'ul.dropdown li.dropdown-menu__item .button:focus'
        );
        const activeElementIndex = [...items].indexOf(focusItems);
        const lastElementIndex = items.length - 1;

        if (activeElementIndex >= 1) {
          items[activeElementIndex - 1].focus();
        } else {
          items[lastElementIndex].focus();
        }
      }
      if (hasPressedArrowDownKey(e)) {
        const items = this.$refs.dropdownMenu.querySelectorAll(
          'li.dropdown-menu__item .button'
        );
        const focusItems = this.$refs.dropdownMenu.querySelector(
          'li.dropdown-menu__item .button:focus'
        );
        const activeElementIndex = [...items].indexOf(focusItems);
        const lastElementIndex = items.length - 1;

        if (activeElementIndex === lastElementIndex) {
          items[0].focus();
        } else {
          items[activeElementIndex + 1].focus();
        }
      }
    },
  },
};
</script>
