<template>
  <li class="dropdown-menu--header" :tabindex="null" :aria-disabled="true">
    <span class="title">{{ title }}</span>
    <slot />
  </li>
</template>
<script>
export default {
  componentName: 'WootDropdownMenu',
  props: {
    title: {
      type: String,
      default: '',
    },
  },
};
</script>
<style lang="scss" scoped>
.dropdown-menu--header {
  list-style: none;

  .title {
    width: 100%;
    display: block;
    text-align: left;
    white-space: nowrap;
    padding: var(--space-small) var(--space-small);
    margin-top: var(--space-smaller);
    font-size: var(--font-size-mini);
    color: var(--s-600);
    font-weight: var(--font-weight-medium);
    border-radius: var(--border-radius-normal);
  }
}
</style>
