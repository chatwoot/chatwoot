<template>
  <div
    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 bg-white dark:bg-slate-800 p-2 border border-slate-100 dark:border-slate-700 rounded-md"
  >
    <div
      v-for="metric in metrics"
      :key="metric.KEY"
      class="p-4 rounded-md mb-3"
    >
      <div>
        <span class="text-sm">{{ metric.NAME }}</span>
        <div class="flex items-end">
          <div class="font-medium text-xl">
            {{ displayMetric(metric.KEY) }}
          </div>
          <div
            v-if="metric.trend"
            class="text-xs ml-4 flex items-center mb-0.5"
          >
            <div
              v-if="metric.trend < 0"
              class="h-0 w-0 border-x-4  medium border-x-transparent border-t-[8px] mr-1 "
              :class="trendColor(metric.trend, metric.KEY)"
            />
            <div
              v-else
              class="h-0 w-0 border-x-4  medium border-x-transparent border-b-[8px] mr-1 "
              :class="trendColor(metric.trend, metric.KEY)"
            />
            <span
              class="font-medium"
              :class="trendColor(metric.trend, metric.KEY)"
            >
              {{ calculateTrend(metric.KEY) }}%
            </span>
          </div>
        </div>
      </div>

      <div class="mt-4 h-72">
        <woot-loading-state
          v-if="accountReport.isFetching[metric.KEY]"
          class="text-xs"
          :message="$t('REPORT.LOADING_CHART')"
        />
        <div v-else class="h-72 flex items-center justify-center">
          <woot-bar
            v-if="accountReport.data[metric.KEY].length"
            :collection="getCollection(metric)"
            :chart-options="getChartOptions(metric)"
            class="h-72 w-full"
          />
          <span v-else class="text-sm text-slate-600">
            {{ $t('REPORT.NO_ENOUGH_DATA') }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { GROUP_BY_FILTER, METRIC_CHART } from './constants';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import { formatTime } from '@chatwoot/utils';
import reportMixin from 'dashboard/mixins/reportMixin';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
};

export default {
  mixins: [reportMixin],
  computed: {
    metrics() {
      const reportKeys = [
        'CONVERSATIONS',
        'FIRST_RESPONSE_TIME',
        'RESOLUTION_TIME',
        'RESOLUTION_COUNT',
        'INCOMING_MESSAGES',
        'OUTGOING_MESSAGES',
      ];
      const infoText = {
        FIRST_RESPONSE_TIME: this.$t(
          `REPORT.METRICS.FIRST_RESPONSE_TIME.INFO_TEXT`
        ),
        RESOLUTION_TIME: this.$t(`REPORT.METRICS.RESOLUTION_TIME.INFO_TEXT`),
      };
      return reportKeys.map(key => ({
        NAME: this.$t(`REPORT.METRICS.${key}.NAME`),
        KEY: REPORTS_KEYS[key],
        DESC: this.$t(`REPORT.METRICS.${key}.DESC`),
        INFO_TEXT: infoText[key],
        TOOLTIP_TEXT: `REPORT.METRICS.${key}.TOOLTIP_TEXT`,
        trend: this.calculateTrend(REPORTS_KEYS[key]),
      }));
    },
  },
  methods: {
    getCollection(metric) {
      if (!this.accountReport.data[metric.KEY]) {
        return {};
      }

      const data = this.accountReport.data[metric.KEY];
      const labels = data.map(element => {
        if (this.groupBy?.period === GROUP_BY_FILTER[2].period) {
          let week_date = new Date(fromUnixTime(element.timestamp));
          const first_day = week_date.getDate() - week_date.getDay();
          const last_day = first_day + 6;

          const week_first_date = new Date(week_date.setDate(first_day));
          const week_last_date = new Date(week_date.setDate(last_day));

          return `${format(week_first_date, 'dd-MMM')} - ${format(
            week_last_date,
            'dd-MMM'
          )}`;
        }
        if (this.groupBy?.period === GROUP_BY_FILTER[3].period) {
          return format(fromUnixTime(element.timestamp), 'MMM-yyyy');
        }
        if (this.groupBy?.period === GROUP_BY_FILTER[4].period) {
          return format(fromUnixTime(element.timestamp), 'yyyy');
        }
        return format(fromUnixTime(element.timestamp), 'dd-MMM');
      });

      const datasets = METRIC_CHART[metric.KEY].datasets.map(dataset => {
        switch (dataset.type) {
          case 'bar':
            return {
              ...dataset,
              yAxisID: 'y-left',
              label: metric.NAME,
              data: data.map(element => element.value),
            };
          case 'line':
            return {
              ...dataset,
              yAxisID: 'y-right',
              label: this.metrics[0].NAME,
              data: data.map(element => element.count),
            };
          default:
            return dataset;
        }
      });
      return {
        labels,
        datasets,
      };
    },
    getChartOptions(metric) {
      let tooltips = {};
      if (this.isAverageMetricType(metric.KEY)) {
        tooltips.callbacks = {
          label: tooltipItem => {
            this.$t(metric.TOOLTIP_TEXT, {
              metricValue: formatTime(tooltipItem.yLabel),
              conversationCount: this.accountReport.data[metric.KEY][
                tooltipItem.index
              ].count,
            });
          },
        };
      }

      return {
        scales: METRIC_CHART[metric.KEY].scales,
        tooltips: tooltips,
      };
    },
    trendColor(value, key) {
      if (
        [
          'avg_first_response_time',
          'avg_resolution_time',
          'reply_time',
        ].includes(key)
      ) {
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
