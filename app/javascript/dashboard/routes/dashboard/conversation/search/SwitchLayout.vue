<template>
  <woot-button
    v-tooltip.left="$t('CONVERSATION.SWITCH_VIEW_LAYOUT')"
    icon="arrow-right-import"
    size="tiny"
    variant="smooth"
    color-scheme="secondary"
    class="layout-switch__container"
    :class="{ expanded: isOnExpandedLayout }"
    @click="toggle"
  />
</template>

<script>
export default {
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    toggle() {
      this.$emit('toggle');
    },
  },
};
</script>

<style lang="scss" soped>
.layout-switch__container {
  align-items: center;
  background-color: var(--s-100);
  border-radius: var(--border-radius-normal);
  cursor: pointer;
  display: flex;
  color: var(--s-600);
  display: flex;
  padding: var(--space-micro) var(--space-smaller);
  width: calc(var(--space-larger) - var(--space-one)) !important;
  &.expanded .icon {
    flex-shrink: 0;
    transform: rotate(180deg);
  }
}
</style>
