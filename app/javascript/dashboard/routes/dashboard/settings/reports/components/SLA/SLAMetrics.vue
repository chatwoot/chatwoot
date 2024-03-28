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
});
</script>

<template>
  <div
    class="flex w-full gap-14 bg-white dark:bg-slate-900 rounded-xl border border-slate-75 dark:border-slate-700/50 px-6 py-4 max-h-[92px] h-full"
  >
    <SLA-metric-card
      :label="$t('SLA_REPORTS.METRICS.HIT_RATE.LABEL')"
      :value="hitRate"
      :tool-tip="$t('SLA_REPORTS.METRICS.HIT_RATE.TOOLTIP')"
    />
    <div class="w-px h-full border border-slate-75 dark:border-slate-700/50" />
    <SLAMetricCard
      label="No of Breaches"
      :value="noOfBreaches"
      :tool-tip="$t('SLA_REPORTS.METRICS.NO_OF_BREACHES.TOOLTIP')"
    />
  </div>
</template>
