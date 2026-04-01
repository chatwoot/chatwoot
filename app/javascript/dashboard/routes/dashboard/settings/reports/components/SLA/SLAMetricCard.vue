<script>
export default {
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: [String, Number],
      required: true,
    },
    toolTip: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-2 items-start justify-center min-w-[10rem]">
    <span
      class="inline-flex items-center gap-1 text-sm font-medium text-on-surface-variant"
    >
      {{ label }}
      <fluent-icon
        v-tooltip.right="toolTip"
        size="14"
        icon="information"
        type="outline"
        class="flex flex-shrink-0 text-sm font-normal sm:font-medium text-on-surface-variant/60"
      />
    </span>
    <div
      v-if="isLoading"
      class="w-12 h-6 mb-0.5 rounded-md bg-surface-container-high animate-pulse"
    />

    <span v-else class="text-2xl font-medium text-on-surface">
      {{ value }}
    </span>
  </div>
</template>
