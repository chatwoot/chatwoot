<script>
export default {
  name: 'WootDropdownItem',
  componentName: 'WootDropdownMenu',
  props: {
    disabled: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<template>
  <li
    class="mb-1 list-none dropdown-menu__item"
    :class="{
      'is-disabled': disabled,
    }"
    :tabindex="disabled ? null : -1"
    :aria-disabled="disabled"
  >
    <slot />
  </li>
</template>

<style lang="scss" scoped>
.dropdown-menu__item {
  ::v-deep {
    a,
    .button {
      @apply inline-flex whitespace-nowrap w-full text-left rtl:text-right;
    }
  }
}

// A hacky fix to remove the background that came from the foundation styles node module file
// Can be removed once we remove the foundation styles node module
.dropdown.menu {
  // Top-level item
  > li > a {
    background: transparent;
    padding: 4px 10.8px;
  }
}
</style>
