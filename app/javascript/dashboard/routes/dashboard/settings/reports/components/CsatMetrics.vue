<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import CsatMetricCard from './CsatMetricCard.vue';
import CsatRatingDistribution from './CsatRatingDistribution.vue';

const metrics = useMapGetter('csat/getMetrics');
const ratingPercentage = useMapGetter('csat/getRatingPercentage');
const ratingCount = useMapGetter('csat/getRatingCount');
const satisfactionScore = useMapGetter('csat/getSatisfactionScore');
const responseRate = useMapGetter('csat/getResponseRate');
const uiFlags = useMapGetter('csat/getUIFlags');

const isLoading = computed(() => uiFlags.value.isFetchingMetrics);

const responseCount = computed(() =>
  metrics.value.totalResponseCount
    ? metrics.value.totalResponseCount.toLocaleString()
    : '0'
);

const formatPercent = value => (value ? `${value}%` : '0%');
</script>

<template>
  <div class="flex flex-col gap-4">
    <div
      class="flex sm:flex-row flex-col w-full gap-4 sm:gap-14 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-6 py-5"
    >
      <CsatMetricCard
        :label="$t('CSAT_REPORTS.METRIC.TOTAL_RESPONSES.LABEL')"
        :tooltip="$t('CSAT_REPORTS.METRIC.TOTAL_RESPONSES.TOOLTIP')"
        :value="responseCount"
        :is-loading="isLoading"
      />

      <div class="w-full sm:w-px bg-n-strong" />

      <CsatMetricCard
        :label="$t('CSAT_REPORTS.METRIC.SATISFACTION_SCORE.LABEL')"
        :tooltip="$t('CSAT_REPORTS.METRIC.SATISFACTION_SCORE.TOOLTIP')"
        :value="formatPercent(satisfactionScore)"
        :is-loading="isLoading"
      />

      <div class="w-full sm:w-px bg-n-strong" />

      <CsatMetricCard
        :label="$t('CSAT_REPORTS.METRIC.RESPONSE_RATE.LABEL')"
        :tooltip="$t('CSAT_REPORTS.METRIC.RESPONSE_RATE.TOOLTIP')"
        :value="formatPercent(responseRate)"
        :is-loading="isLoading"
      />
    </div>

    <CsatRatingDistribution
      :rating-percentage="ratingPercentage"
      :rating-count="ratingCount"
      :total-response-count="metrics.totalResponseCount"
      :is-loading="isLoading"
    />
  </div>
</template>
