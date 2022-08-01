<template>
  <button
    v-tooltip.left="$t('CONVERSATION.SWITCH_VIEW_LAYOUT')"
    class="layout-switch__container"
    @click="toggle"
  >
    <div
      class="layout-switch__btn left"
      :class="{ active: !isOnExpandedLayout }"
    >
      <fluent-icon icon="panel-sidebar" :size="16" />
    </div>
    <div
      class="layout-switch__btn right"
      :class="{ active: isOnExpandedLayout }"
    >
      <fluent-icon icon="panel-contract" :size="16" />
    </div>
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
  border-radius: var(--border-radius-medium);
  cursor: pointer;
  display: flex;
  padding: var(--space-micro);

  .layout-switch__btn {
    border-radius: var(--border-radius-normal);
    color: var(--s-400);
    display: flex;
    padding: var(--space-micro) var(--space-smaller);

    &.active {
      background-color: var(--white);
      color: var(--w-500);
    }
  }
}
</style>
