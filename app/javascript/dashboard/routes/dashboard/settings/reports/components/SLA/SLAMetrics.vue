<template>
  <div
    class="flex flex-col w-full gap-4 px-6 py-4 border bg-ash-50 sm:flex-row sm:gap-14 rounded-xl border-slate-75 dark:border-slate-700/50"
  >
    <SLAMetricCard
      :label="$t('SLA_REPORTS.METRICS.HIT_RATE.LABEL')"
      :value="hitRate"
      :tool-tip="$t('SLA_REPORTS.METRICS.HIT_RATE.TOOLTIP')"
      :is-loading="isLoading"
    />

    <div
      class="w-full h-full border sm:w-px border-slate-75 dark:border-slate-700/50"
    />
    <SLAMetricCard
      :label="$t('SLA_REPORTS.METRICS.NO_OF_MISSES.LABEL')"
      :value="noOfBreaches"
      :tool-tip="$t('SLA_REPORTS.METRICS.NO_OF_MISSES.TOOLTIP')"
      :is-loading="isLoading"
    />
    <div
      class="w-full h-full border sm:w-px border-slate-75 dark:border-slate-700/50"
    />
    <SLAMetricCard
      :label="$t('SLA_REPORTS.METRICS.NO_OF_CONVERSATIONS.LABEL')"
      :value="noOfConversations"
      :tool-tip="$t('SLA_REPORTS.METRICS.NO_OF_CONVERSATIONS.TOOLTIP')"
      :is-loading="isLoading"
    />
  </div>
</template>

<script setup>
import SLAMetricCard from './SLAMetricCard.vue';
defineProps({
  hitRate: {
    type: String,
    required: true,
  },
  noOfBreaches: {
    type: Number,
    required: true,
  },
  noOfConversations: {
    type: Number,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});
</script>
