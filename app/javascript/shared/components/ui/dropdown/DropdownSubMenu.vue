<template>
  <li class="sub-menu-container">
    <div class="sub-menu-title">
      <small>{{ title }}</small>
    </div>
    <ul class="sub-menu-li-container">
      <slot></slot>
    </ul>
  </li>
</template>
<script>
export default {
  name: 'WootDropdownMenu',
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
.sub-menu-container {
  border-top: 1px solid var(--color-border);
  &:not(:last-child) {
    border-bottom: 1px solid var(--color-border);
  }
}
.sub-menu-title {
  padding: var(--space-one) var(--space-one) var(--space-smaller);
  text-transform: uppercase;
  small {
    font-weight: var(--font-weight-medium);
    color: var(--b-600);
  }
}
.sub-menu-li-container {
  margin: 0;
}
</style>
