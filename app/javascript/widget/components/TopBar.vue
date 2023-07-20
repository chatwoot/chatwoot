<template>
  <div
    class="flex px-4 py-2 items-center justify-between sticky w-full top-0 h-8 top-bar"
  >
    <button
      class="inline-flex px-2 py-1 items-center justify-center rounded  brand-dark-button"
      @click="onBack"
    >
      <fluent-icon icon="chevron-left" size="12" />
    </button>
    <button
      class="inline-flex px-2 py-1 items-center justify-center rounded brand-dark-button"
      @click="onClose"
    >
      <fluent-icon icon="dismiss" size="12" />
    </button>
  </div>
</template>

<script>
export default {
  methods: {
    onBack() {
      this.$emit('back');
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style lang="scss">
.brand-dark-button {
  background: var(--brand-bgDarker);
  svg {
    color: var(--brand-body);
  }
}

.top-bar {
  background: var(--brand-bgDark);
  color: var(--brand-body);
}
</style>
