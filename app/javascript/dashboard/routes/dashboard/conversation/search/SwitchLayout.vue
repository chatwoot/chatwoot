<script>
export default {
  props: {
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['toggle'],
  methods: {
    toggle() {
      this.$emit('toggle');
    },
  },
};
</script>

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

<style lang="scss" soped>
.layout-switch__container {
  &.expanded .icon {
    transform: rotate(180deg);
  }
}
</style>
