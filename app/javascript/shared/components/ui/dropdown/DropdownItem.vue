<template>
  <li
    class="dropdown-menu__item"
    :class="{
      'is-disabled': disabled,
    }"
    :tabindex="disabled ? null : -1"
    :aria-disabled="disabled"
  >
    <slot></slot>
  </li>
</template>
<script>
export default {
  name: 'WootDropdownItem',
  componentName: 'WootDropdownMenu',
  props: {
    disabled: {
      type: Boolean,
      default: false,
    },
    className: {
      type: String,
      default: '',
    },
  },
};
</script>
<style lang="scss" scoped>
.dropdown-menu__item {
  list-style: none;

  ::v-deep {
    a,
    .button {
      width: 100%;
      text-align: left;
      white-space: nowrap;
      padding: var(--space-small) var(--space-one);

      &:hover {
        background: var(--color-background);
        border-radius: var(--border-radius-normal);
      }
    }
  }
}
</style>
