<template>
  <SLA-metrics-layout :is-loading="isLoading">
    <template #loading>
      <div class="w-12 h-6 mb-0.5 rounded-md bg-slate-50 animate-pulse" />
    </template>
    <template #label>
      <span
        class="inline-flex items-center gap-1 text-sm text-slate-700 dark:text-slate-200 font-medium"
      >
        {{ label }}
        <fluent-icon
          v-tooltip.right="toolTip"
          size="14"
          icon="information"
          type="outline"
          class="flex-shrink-0 text-sm font-normal flex sm:font-medium text-slate-500 dark:text-slate-500"
        />
      </span>
    </template>
    <template #value>
      <span class="text-2xl font-medium text-slate-900 dark:text-slate-25">
        {{ value }}
      </span>
    </template>
  </SLA-metrics-layout>
</template>
<script>
import SLAMetricsLayout from './SLAMetricsLayout.vue';
export default {
  components: {
    SLAMetricsLayout,
  },
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
