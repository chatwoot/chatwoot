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

  ::v-deep {
    a,
    .button {
      width: 100%;
      text-align: left;
      color: var(--s-700);
      white-space: nowrap;
      display: inline-flex;
      padding: var(--space-small);
      padding-top: var(--space-small);
      padding-bottom: var(--space-small);
      border-radius: var(--border-radius-normal);

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
