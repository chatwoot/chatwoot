<template>
  <li class="sub-menu-container">
    <div class="sub-menu-title">
      <span class="small">{{ title }}</span>
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
  margin-top: var(--space-micro);

  &:not(:last-child) {
    border-bottom: 1px solid var(--color-border);
  }
}
.sub-menu-title {
  padding: var(--space-one) var(--space-one) var(--space-smaller);
  text-transform: uppercase;

  .small {
    color: var(--b-600);
    font-weight: var(--font-weight-medium);
  }
}

.sub-menu-li-container {
  margin: 0;
}
</style>
