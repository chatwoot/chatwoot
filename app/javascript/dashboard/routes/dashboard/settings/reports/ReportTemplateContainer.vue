<template>
  <div
    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 bg-white dark:bg-slate-800 p-2 border border-slate-100 dark:border-slate-700 rounded-md"
  >
    <div
      v-for="metric in metrics"
      :key="metric.KEY"
      class="p-4 rounded-md mb-3"
    >
      <chart-stats
        :metric="metric"
        :template-summary-key="templateSummaryKey"
      />
      <div class="mt-4 h-72">
        <woot-loading-state
          v-if="templateReport.isFetching[metric.KEY]"
          class="text-xs"
          :message="$t('REPORT.LOADING_CHART')"
        />
        <div v-else class="h-72 flex items-center justify-center">
          <woot-bar
            v-if="templateReport.data[metric.KEY].length"
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
import { GROUP_BY_FILTER, TEMPLATE_METRIC_CHART } from './constants';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import { formatTime } from '@chatwoot/utils';
import reportMixin from 'dashboard/mixins/reportMixin';
import ChartStats from './components/ChartElements/ChartStats.vue';

export default {
  components: { ChartStats },
  mixins: [reportMixin],
  props: {
    groupBy: {
      type: Object,
      default: () => ({}),
    },
    reportKeys: {
      type: Object,
      default: () => ({
        MESSAGES_SENT: 'messages_sent',
        MESSAGES_DELIVERED: 'messages_delivered',
        MESSAGES_READ: 'messages_read',
      }),
    },
  },

  computed: {
    metrics() {
      const reportKeys = Object.keys(this.reportKeys);
      return reportKeys.map(key => ({
        NAME: this.$t(`TEMPLATE_REPORTS.METRICS.${key}.NAME`),
        KEY: this.reportKeys[key],
        DESC: this.$t(`TEMPLATE_REPORTS.METRICS.${key}.DESC`),
        INFO_TEXT: 'test',
        TOOLTIP_TEXT: `TEMPLATE_REPORTS.METRICS.${key}.TOOLTIP_TEXT`,
        trend: this.calculateTrend(this.reportKeys[key]),
      }));
    },
  },
  methods: {
    getCollection(metric) {
      if (!this.templateReport.data[metric?.KEY]) {
        return {};
      }
      const data = this.templateReport.data[metric.KEY];
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
      const datasets = TEMPLATE_METRIC_CHART[metric.KEY].datasets.map(
        dataset => {
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
        }
      );

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
            return this.$t(metric.TOOLTIP_TEXT, {
              metricValue: formatTime(tooltipItem.yLabel),
              conversationCount:
                this.templateReport.data[metric.KEY][tooltipItem.index].count,
            });
          },
        };
      }

      return {
        scales: TEMPLATE_METRIC_CHART[metric.KEY].scales,
        tooltips: tooltips,
      };
    },
  },
};
</script>
