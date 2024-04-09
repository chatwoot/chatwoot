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
    required: true,
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
    class="m-0 p-4"
    :class="{
      'grayscale pointer-events-none opacity-30': disabled,
    }"
  >
    <h3
      class="flex items-center text-sm font-medium m-0 text-slate-800 dark:text-slate-100"
    >
      <span ref="reportMetricLabel">{{ label }}</span>
      <fluent-icon
        ref="reportMetricInfo"
        v-tooltip="infoText"
        size="14"
        icon="info"
        class="text-slate-500 dark:text-slate-200 my-0 mx-1 mt-0.5"
      />
    </h3>
    <h4
      ref="reportMetricValue"
      class="text-slate-700 dark:text-slate-100 mb-0 mt-1 font-thin text-3xl"
    >
      {{ value }}
    </h4>
  </div>
</template>
