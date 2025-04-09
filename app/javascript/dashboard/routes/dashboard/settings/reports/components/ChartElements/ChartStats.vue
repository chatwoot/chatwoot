<script setup>
import { useReportMetrics } from 'dashboard/composables/useReportMetrics';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
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
});

const STATUS = {
  FAILED: 'failed',
  FETCHING: 'fetching',
  FINISHED: 'finished',
};

const { t } = useI18n();

const { calculateTrend, displayMetric, isAverageMetricType, getStatus } =
  useReportMetrics(props.accountSummaryKey);

const trendColor = (value, key) => {
  if (isAverageMetricType(key)) {
    return value > 0
      ? 'border-red-500 text-red-500'
      : 'border-green-500 text-green-500';
  }
  return value < 0
    ? 'border-red-500 text-red-500'
    : 'border-green-500 text-green-500';
};
</script>

<template>
  <div class="text-n-slate-11">
    <span class="text-sm">
      {{ metric.NAME }}
    </span>
    <div class="flex items-end text-n-slate-12">
      <div v-if="getStatus(metric.KEY) === STATUS.FETCHING">
        <Spinner />
      </div>
      <div
        v-else-if="getStatus(metric.KEY) === STATUS.FAILED"
        class="text-n-ruby-10 text-sm"
      >
        {{ t('REPORT.SUMMARY_FETCHING_FAILED') }}
      </div>
      <div
        v-else-if="getStatus(metric.KEY) === STATUS.FINISHED"
        class="text-xl font-medium"
      >
        {{ displayMetric(metric.KEY) }}
      </div>
      <div
        v-if="metric.trend && getStatus(metric.KEY) === STATUS.FINISHED"
        class="text-xs ml-4 flex items-center mb-0.5"
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
          {{ calculateTrend(metric.KEY) }}%
        </span>
      </div>
    </div>
  </div>
</template>
