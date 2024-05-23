<template>
  <div class="text-slate-900 dark:text-slate-100">
    <span class="text-sm">
      {{ metric.NAME }}
    </span>
    <div class="flex items-end">
      <div class="font-medium text-xl">
        {{ displayMetric(metric.KEY) }}
      </div>
      <div v-if="metric.trend" class="text-xs ml-4 flex items-center mb-0.5">
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
<script>
import reportMixin from 'dashboard/mixins/reportMixin';
export default {
  mixins: [reportMixin],
  props: {
    metric: {
      type: Object,
      default: () => ({}),
    },
  },
  methods: {
    trendColor(value, key) {
      if (this.isAverageMetricType(key)) {
        return value > 0
          ? 'border-red-500 text-red-500'
          : 'border-green-500 text-green-500';
      }
      return value < 0
        ? 'border-red-500 text-red-500'
        : 'border-green-500 text-green-500';
    },
  },
};
</script>
