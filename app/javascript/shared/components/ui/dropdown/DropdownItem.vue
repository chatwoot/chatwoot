<template>
  <li
    class="dropdown-menu__item"
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
  list-style: none;
  margin-bottom: var(--space-micro);

  ::v-deep {
    a,
    .button {
      display: inline-flex;
      white-space: nowrap;
      width: 100%;
      text-align: left;
      color: var(--s-700);

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
