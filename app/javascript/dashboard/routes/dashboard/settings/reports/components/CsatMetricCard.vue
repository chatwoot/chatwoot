<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  tooltip: {
    type: String,
    required: true,
  },
  value: {
    type: [String, Number],
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div class="flex flex-col gap-2 items-start justify-center min-w-[10rem]">
    <span
      class="inline-flex items-center gap-1 text-sm font-medium text-on-surface-variant"
    >
      {{ label }}
      <span
        v-tooltip.right="tooltip"
        class="i-lucide-info flex flex-shrink-0 text-on-surface-variant/60 size-3.5"
      />
    </span>
    <div
      v-if="isLoading"
      class="w-16 h-8 rounded-md bg-surface-container-high animate-pulse"
    />
    <span v-else class="text-2xl font-medium text-on-surface">
      {{ value }}
    </span>
  </div>
</template>
