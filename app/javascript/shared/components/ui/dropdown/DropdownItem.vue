<template>
  <li
    class="dropdown-menu__item list-none mb-1"
    :class="{
      'is-disabled': disabled,
    }"
    :tabindex="disabled ? null : -1"
    :aria-disabled="disabled"
  >
    <slot />
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
  ::v-deep {
    a,
    .button {
      display: inline-flex;
      white-space: nowrap;
      width: 100%;
      text-align: left;

      &:hover {
        background: var(--color-background);
      }

      &:focus {
        background: var(--color-background);
      }
    }
  }
}
</style>
