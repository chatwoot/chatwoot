<script setup>
defineProps({
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
});
</script>

<template>
  <div class="flex flex-col gap-2 items-start justify-center min-w-[160px]">
    <span
      class="inline-flex items-center gap-1 tracking-[-0.6%] text-sm text-slate-700 dark:text-slate-200 font-medium"
    >
      {{ label }}
      <fluent-icon
        v-tooltip.right="toolTip"
        size="14"
        icon="information"
        type="outline"
        class="flex-shrink-0 hidden text-sm font-normal sm:flex sm:font-medium text-slate-500 dark:text-slate-500"
      />
    </span>
    <span
      class="text-2xl font-medium text-slate-900 dark:text-slate-25 tracking-[-1.5%]"
    >
      {{ value }}
    </span>
  </div>
</template>
