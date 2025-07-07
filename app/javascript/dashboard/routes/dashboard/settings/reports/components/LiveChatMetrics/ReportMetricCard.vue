<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  value: {
    type: String,
    required: true,
  },
  infoText: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});
</script>
<template>
  <div
    ref="reportMetricContainer"
    class="rounded-lg shadow-sm border border-[#eaecf0] dark:border-[#4C5155]"
    :class="{
      'grayscale pointer-events-none opacity-30': disabled,
    }"
  >
    <div class="flex flex-col space-y-1.5 p-6 pb-2">
      <div class="flex gap-3 items-center">
        <div class="tracking-tight text-sm font-medium">{{ label }}</div>
        <fluent-icon
          v-if="infoText"
          ref="reportMetricInfo"
          v-tooltip="infoText"
          size="14"
          icon="info"
          class="text-slate-500 dark:text-slate-200 my-0 mx-1 mt-0.5"
        />
      </div>
    </div>
    <div ref="reportMetricValue" class="p-6 pt-0">
      <div class="text-2xl font-bold">{{ value }}</div>
    </div>
  </div>
</template>
