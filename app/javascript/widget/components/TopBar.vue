<template>
  <div
    class="flex px-4 py-2 items-center justify-between sticky w-full top-0 h-8 bg-slate-25 bg-brand-dark"
  >
    <button
      class="inline-flex px-2 py-1 items-center justify-center rounded bg-slate-75 bg-brand-button-dark hover:bg-white"
      @click="onBack"
    >
      <fluent-icon icon="chevron-left" size="12" class="text-brand-body" />
    </button>
    <button
      class="inline-flex px-2 py-1 items-center justify-center rounded bg-slate-75 bg-brand-button-dark hover:bg-white"
      @click="onClose"
    >
      <fluent-icon icon="dismiss" size="12" class="text-brand-body" />
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
