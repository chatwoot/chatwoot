<template>
  <button
    v-tooltip="$t('CONVERSATION.SWITCH_VIEW_LAYOUT')"
    class="layout-switch__container"
    @click="toggle"
  >
    <div class="layout-switch__btn left" :class="{ active: wideScreen }">
      <fluent-icon icon="panel-sidebar" />
    </div>
    <div class="layout-switch__btn right" :class="{ active: !wideScreen }">
      <fluent-icon icon="panel-contract" />
    </div>
  </button>
</template>

<script>
export default {
  data() {
    return {
      wideScreen: false,
    };
  },
  methods: {
    toggle() {
      this.wideScreen = !this.wideScreen;
      this.$emit('toggle');
    },
  },
};
</script>

<style lang="scss" soped>
.layout-switch__container {
  display: flex;
  align-items: center;
  border-radius: var(--border-radius-medium);
  background-color: var(--s-100);
  padding: var(--space-micro);
  cursor: pointer;

  .layout-switch__btn {
    padding: var(--space-micro) var(--space-half);
    border-radius: var(--border-radius-normal);
    color: var(--s-400);
    &.active {
      background-color: var(--white);
      color: var(--w-500);
    }
  }
}
</style>
