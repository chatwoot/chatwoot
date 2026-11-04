<script>
import { mapGetters } from 'vuex';
import { useReportMetrics } from 'dashboard/composables/useReportMetrics';
import { GROUP_BY_FILTER } from './constants';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import { formatTime } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import ChartStats from './components/ChartElements/ChartStats.vue';
import BarChart from 'shared/components/charts/BarChart.vue';
import ReportDrilldownDrawer from './components/ReportDrilldownDrawer.vue';

const DURATION_UNITS_IN_SECONDS = [
  1,
  60,
  60 * 60,
  24 * 60 * 60,
  7 * 24 * 60 * 60,
  30 * 24 * 60 * 60,
  365 * 24 * 60 * 60,
];
const DURATION_STEP_MULTIPLIERS = [1, 2, 3, 5, 6, 10, 12, 15, 30];
const DURATION_STEP_SIZES = [
  ...new Set(
    DURATION_UNITS_IN_SECONDS.flatMap(unit =>
      DURATION_STEP_MULTIPLIERS.map(multiplier => unit * multiplier)
    )
  ),
].sort((first, second) => first - second);

export default {
  components: { ChartStats, BarChart, ReportDrilldownDrawer },
  props: {
    groupBy: {
      type: Object,
      default: () => ({}),
    },
    from: {
      type: Number,
      default: 0,
    },
    to: {
      type: Number,
      default: 0,
    },
    reportType: {
      type: String,
      default: 'account',
    },
    selectedItemId: {
      type: [String, Number],
      default: null,
    },
    businessHours: {
      type: Boolean,
      default: false,
    },
    accountSummaryKey: {
      type: String,
      default: 'getAccountSummary',
    },
    summaryFetchingKey: {
      type: String,
      default: 'getAccountSummaryFetchingStatus',
    },
    reportKeys: {
      type: Object,
      default: () => ({
        CONVERSATIONS: 'conversations_count',
        INCOMING_MESSAGES: 'incoming_messages_count',
        OUTGOING_MESSAGES: 'outgoing_messages_count',
        FIRST_RESPONSE_TIME: 'avg_first_response_time',
        RESOLUTION_TIME: 'avg_resolution_time',
        RESOLUTION_COUNT: 'resolutions_count',
        REPLY_TIME: 'reply_time',
      }),
    },
  },
  setup(props) {
    const { calculateTrend, isAverageMetricType } = useReportMetrics(
      props.accountSummaryKey
    );
    return { calculateTrend, isAverageMetricType };
  },
  data() {
    return {
      drilldownRequest: null,
      drilldownMetric: null,
      drilldownIndex: null,
    };
  },
  computed: {
    ...mapGetters({
      accountReport: 'getAccountReports',
      currentRole: 'getCurrentRole',
    }),
    isAdmin() {
      return this.currentRole === 'administrator';
    },
    canDrilldownPrev() {
      return this.findDrillableIndex(this.drilldownIndex - 1, -1) !== null;
    },
    canDrilldownNext() {
      return this.findDrillableIndex(this.drilldownIndex + 1, 1) !== null;
    },
    metrics() {
      const reportKeys = Object.keys(this.reportKeys);
      const infoText = {
        FIRST_RESPONSE_TIME: this.$t(
          `REPORT.METRICS.FIRST_RESPONSE_TIME.INFO_TEXT`
        ),
        RESOLUTION_TIME: this.$t(`REPORT.METRICS.RESOLUTION_TIME.INFO_TEXT`),
      };
      return reportKeys.map(key => ({
        NAME: this.$t(`REPORT.METRICS.${key}.NAME`),
        KEY: this.reportKeys[key],
        DESC: this.$t(`REPORT.METRICS.${key}.DESC`),
        INFO_TEXT: infoText[key],
        trend: this.calculateTrend(this.reportKeys[key]),
      }));
    },
  },
  methods: {
    getChartData(metric) {
      if (!this.accountReport.data[metric.KEY]) {
        return { categories: [], series: [] };
      }
      const data = this.accountReport.data[metric.KEY];
      const categories = data.map(element => {
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

      return {
        categories,
        series: [
          {
            id: metric.KEY,
            label:
              metric.KEY === 'reply_time'
                ? this.$t('REPORT.METRICS.REPLY_TIME.TOOLTIP_LABEL')
                : metric.NAME,
            color: 'rgb(var(--blue-9))',
            data,
          },
        ],
      };
    },
    getChartAriaLabel(metric) {
      const groupingLabels = {
        day: this.$t('REPORT.GROUPING_OPTIONS.DAY'),
        week: this.$t('REPORT.GROUPING_OPTIONS.WEEK'),
        month: this.$t('REPORT.GROUPING_OPTIONS.MONTH'),
        year: this.$t('REPORT.GROUPING_OPTIONS.YEAR'),
      };
      return `${metric.NAME}, ${groupingLabels[this.groupBy.period]}`;
    },
    getValueFormatter(metric) {
      if (!this.isAverageMetricType(metric.KEY)) {
        return value => Number(value).toLocaleString();
      }

      return (value, dataPoint) => {
        if (!dataPoint && value === 0) return '0';

        return formatTime(value || 0);
      };
    },
    getPointDescription(metric) {
      if (metric.KEY === 'avg_first_response_time') {
        return dataPoint =>
          this.$t('REPORT.METRICS.FIRST_RESPONSE_TIME.TOOLTIP_DESCRIPTION', {
            count: dataPoint.count || 0,
          });
      }

      if (metric.KEY === 'avg_resolution_time') {
        return dataPoint =>
          this.$t('REPORT.METRICS.RESOLUTION_TIME.TOOLTIP_DESCRIPTION', {
            count: dataPoint.count || 0,
          });
      }

      if (metric.KEY !== 'reply_time') return undefined;

      return dataPoint =>
        this.$t('REPORT.METRICS.REPLY_TIME.TOOLTIP_DESCRIPTION', {
          count: dataPoint.count || 0,
        });
    },
    getDurationStepSize({ min, max, tickCount }) {
      const targetStep = (max - min) / Math.max(tickCount - 1, 1);

      return DURATION_STEP_SIZES.reduce((closestStep, step) => {
        return Math.abs(step - targetStep) < Math.abs(closestStep - targetStep)
          ? step
          : closestStep;
      });
    },
    isDrilldownEnabled() {
      return !!(this.from && this.to);
    },
    onChartElementClick(metric, event) {
      if (!this.isDrilldownEnabled()) return;

      const dataPoint = event.item;
      if (!this.canOpenDrilldown(metric, dataPoint)) return;
      if (!this.isAdmin) {
        useAlert(this.$t('REPORT.DRILLDOWN.ADMIN_ONLY'));
        return;
      }

      this.openDrilldownAt(metric, event.pointIndex);
    },
    openDrilldownAt(metric, dataIndex) {
      const dataPoint = this.accountReport.data[metric.KEY]?.[dataIndex];
      if (!this.canOpenDrilldown(metric, dataPoint)) return;

      const categories = this.getChartData(metric).categories;

      this.drilldownMetric = metric;
      this.drilldownIndex = dataIndex;
      this.drilldownRequest = {
        metric: metric.KEY,
        metricName: metric.NAME,
        bucketLabel: categories[dataIndex],
        bucketTimestamp: dataPoint.timestamp,
        bucketValue: dataPoint.value,
        isAverageMetric: this.isAverageMetricType(metric.KEY),
        from: this.from,
        to: this.to,
        type: this.reportType,
        id: this.selectedItemId,
        groupBy: this.groupBy?.period,
        businessHours: this.businessHours,
      };
    },
    navigateDrilldown(direction) {
      const nextIndex = this.findDrillableIndex(
        this.drilldownIndex + direction,
        direction
      );
      if (nextIndex === null) return;

      this.openDrilldownAt(this.drilldownMetric, nextIndex);
    },
    findDrillableIndex(startIndex, step) {
      if (!this.drilldownMetric) return null;

      const data = this.accountReport.data[this.drilldownMetric.KEY] || [];
      for (
        let index = startIndex;
        index >= 0 && index < data.length;
        index += step
      ) {
        if (this.canOpenDrilldown(this.drilldownMetric, data[index]))
          return index;
      }

      return null;
    },
    canOpenDrilldown(metric, dataPoint) {
      if (!dataPoint) return false;

      if (this.isAverageMetricType(metric.KEY)) {
        return dataPoint.count > 0;
      }

      return dataPoint.value > 0;
    },
    closeDrilldown() {
      this.drilldownRequest = null;
      this.drilldownMetric = null;
      this.drilldownIndex = null;
    },
  },
};
</script>

<template>
  <div
    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 px-6 py-5 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 mt-4"
  >
    <div
      v-for="metric in metrics"
      :key="metric.KEY"
      class="py-4 mb-3 rounded-md"
    >
      <ChartStats
        :metric="metric"
        :account-summary-key="accountSummaryKey"
        :summary-fetching-key="summaryFetchingKey"
        class="px-4"
      />
      <div class="mt-4 h-72">
        <woot-loading-state
          v-if="accountReport.isFetching[metric.KEY]"
          class="text-xs"
          :message="$t('REPORT.LOADING_CHART')"
        />
        <div v-else class="flex items-center justify-center min-w-0 h-72">
          <BarChart
            v-if="accountReport.data[metric.KEY].length"
            :data="getChartData(metric)"
            :aria-label="getChartAriaLabel(metric)"
            :format-value="getValueFormatter(metric)"
            :point-description="getPointDescription(metric)"
            :y-step-size="
              isAverageMetricType(metric.KEY) ? getDurationStepSize : undefined
            "
            :height="288"
            timeseries
            :clickable="isDrilldownEnabled()"
            @item-click="onChartElementClick(metric, $event)"
          />
          <span v-else class="text-sm text-n-slate-10">
            {{ $t('REPORT.NO_ENOUGH_DATA') }}
          </span>
        </div>
      </div>
    </div>
  </div>
  <ReportDrilldownDrawer
    :id="drilldownRequest?.id"
    :open="!!drilldownRequest"
    :metric="drilldownRequest?.metric"
    :metric-name="drilldownRequest?.metricName"
    :bucket-label="drilldownRequest?.bucketLabel"
    :bucket-timestamp="drilldownRequest?.bucketTimestamp"
    :bucket-value="drilldownRequest?.bucketValue"
    :is-average-metric="drilldownRequest?.isAverageMetric"
    :from="drilldownRequest?.from"
    :to="drilldownRequest?.to"
    :type="drilldownRequest?.type"
    :group-by="drilldownRequest?.groupBy"
    :business-hours="drilldownRequest?.businessHours"
    :can-prev="canDrilldownPrev"
    :can-next="canDrilldownNext"
    @navigate="navigateDrilldown"
    @close="closeDrilldown"
  />
</template>
