<template>
  <button
    v-tooltip.left="$t('CONVERSATION.SWITCH_VIEW_LAYOUT')"
    class="layout-switch__container"
    @click="toggle"
  >
    <fluent-icon
      icon="arrow-right-import"
      :size="16"
      :class="{ expanded: isOnExpandedLayout }"
    />
  </button>
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

  .expanded {
    transform: rotate(180deg);
  }
}
</style>
