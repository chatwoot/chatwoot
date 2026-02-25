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
      class="inline-flex items-center gap-1 text-sm font-medium text-n-slate-11"
    >
      {{ label }}
      <span
        v-tooltip.right="tooltip"
        class="i-lucide-info flex flex-shrink-0 text-n-slate-10 size-3.5"
      />
    </span>
    <div
      v-if="isLoading"
      class="w-16 h-8 rounded-md bg-n-slate-3 animate-pulse"
    />
    <span v-else class="text-2xl font-medium text-n-slate-12">
      {{ value }}
    </span>
  </div>
</template>
