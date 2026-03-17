<script setup>
import { useReportMetrics } from 'dashboard/composables/useReportMetrics';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { STATUS } from 'dashboard/store/constants';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  metric: {
    type: Object,
    default: () => ({}),
  },
  accountSummaryKey: {
    type: String,
    default: 'getAccountSummary',
  },
  summaryFetchingKey: {
    type: String,
    default: 'getAccountSummaryFetchingStatus',
  },
});

const { t } = useI18n();

const trendText = value =>
  `${Math.abs(value)}${t('REPORT.SYNAPSEA_ANALYTICS.PERCENT_SUFFIX')}`;

const { calculateTrend, displayMetric, isAverageMetricType, fetchingStatus } =
  useReportMetrics(props.accountSummaryKey, props.summaryFetchingKey);

const trendColor = (value, key) => {
  if (isAverageMetricType(key)) {
    return value > 0
      ? 'border-n-ruby-9 text-n-ruby-9'
      : 'border-n-teal-10 text-n-teal-10';
  }
  return value < 0
    ? 'border-n-ruby-9 text-n-ruby-9'
    : 'border-n-teal-10 text-n-teal-10';
};
</script>

<template>
  <div class="text-n-slate-11">
    <span class="text-sm font-medium">
      {{ metric.NAME }}
    </span>
    <div class="mt-1 flex items-end text-n-slate-12">
      <div v-if="fetchingStatus === STATUS.FETCHING">
        <Spinner />
      </div>
      <div
        v-else-if="fetchingStatus === STATUS.FAILED"
        class="text-n-ruby-10 text-sm"
      >
        {{ t('REPORT.SUMMARY_FETCHING_FAILED') }}
      </div>
      <div
        v-else-if="fetchingStatus === STATUS.FINISHED"
        class="text-2xl font-semibold"
      >
        {{ displayMetric(metric.KEY) }}
      </div>
      <div
        v-if="metric.trend && fetchingStatus === STATUS.FINISHED"
        class="mb-0.5 ml-4 flex items-center rounded-md border border-n-weak bg-n-solid-1 px-2 py-1 text-xs"
      >
        <div
          v-if="metric.trend < 0"
          class="h-0 w-0 border-x-4 medium border-x-transparent border-t-[8px] mr-1"
          :class="trendColor(metric.trend, metric.KEY)"
        />
        <div
          v-else
          class="h-0 w-0 border-x-4 medium border-x-transparent border-b-[8px] mr-1"
          :class="trendColor(metric.trend, metric.KEY)"
        />
        <span class="font-medium" :class="trendColor(metric.trend, metric.KEY)">
          {{ trendText(calculateTrend(metric.KEY)) }}
        </span>
      </div>
    </div>
  </div>
</template>
