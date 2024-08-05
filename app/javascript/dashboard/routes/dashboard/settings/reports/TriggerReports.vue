<template>
  <div class="flex-1 overflow-auto p-4">
    <report-filters
      type="triggers"
      :group-by-filter-items-list="groupByFilterItemsList"
      @date-range-change="onDateRangeChange"
      @business-hours-toggle="onBusinessHoursToggle"
      @group-by-filter-change="onGroupByFilterChange"
    />
    <div class="row">
      <metric-card
        :is-live="false"
        :is-loading="triggersMetric.isFetchingMetrics"
        :header="$t('TRIGGER_REPORTS.SUBTITLE')"
        :loading-message="$t('REPORT.LOADING_CHART')"
      >
        <div
          v-for="(metric, name, index) in conversationMetrics"
          :key="index"
          class="metric-content column"
        >
          <h3 class="heading">{{ name }}</h3>
          <p class="metric">{{ metric }}</p>
        </div>
      </metric-card>
    </div>
    <div class="row">
      <metric-card :header="$t('TRIGGER_REPORTS.GRAPH_TITLE')">
        <div class="metric-content column">
          <woot-loading-state
            v-if="triggersMetric.isFetching"
            class="text-xs"
            :message="$t('REPORT.LOADING_CHART')"
          />
          <div v-else class="flex items-center justify-center">
            <woot-bar
              v-if="chartData.datasets.length"
              :collection="chartData"
              class="w-full"
            />
            <span v-else class="text-sm text-slate-600">
              {{ $t('REPORT.NO_ENOUGH_DATA') }}
            </span>
          </div>
        </div>
      </metric-card>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { TRIGGERS_METRICS, GROUP_BY_FILTER } from './constants';
import MetricCard from './components/overview/MetricCard.vue';
import ReportFilters from './components/ReportFilters.vue';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

export default {
  name: 'TriggerReports',
  components: {
    MetricCard,
    ReportFilters,
  },
  data() {
    return {
      chartData: {
        labels: [],
        datasets: [],
      },
      from: Math.floor(new Date().setMonth(new Date().getMonth() - 6) / 1000),
      to: Math.floor(Date.now() / 1000),
      groupBy: null,
    };
  },
  computed: {
    ...mapGetters({
      triggersMetric: 'getTriggersReport',
    }),
    groupByFilterItemsList() {
      return this.$t('REPORT.GROUP_BY_YEAR_OPTIONS');
    },
    conversationMetrics() {
      let metric = {};
      Object.keys(this.triggersMetric.metrics || {}).forEach(key => {
        const metricName = this.$t(
          'TRIGGER_REPORTS.METRICS.' + TRIGGERS_METRICS[key] + '.NAME'
        );
        metric[metricName] = this.triggersMetric.metrics[key];
      });
      return metric;
    },
  },
  watch: {
    triggersMetric: {
      immediate: true,
      handler(newVal) {
        if (!newVal.isFetching && newVal.data) {
          this.prepareChartData();
        }
      },
      deep: true,
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    getDateFormat(groupBy) {
      if (
        groupBy === GROUP_BY_FILTER[1].period ||
        groupBy === GROUP_BY_FILTER[2].period
      ) {
        return 'dd-MMM';
      }
      if (groupBy === GROUP_BY_FILTER[3].period) {
        return 'MMM-yyyy';
      }
      if (groupBy === GROUP_BY_FILTER[4].period) {
        return 'yyyy';
      }

      return 'dd';
    },
    prepareChartData() {
      const data = this.triggersMetric.data || [];
      const labels = data.map(item =>
        format(fromUnixTime(item.timestamp), this.getDateFormat(this.groupBy))
      );
      const values = data.map(item => item.count);
      this.chartData = {
        labels,
        datasets: [
          {
            label: 'Número de Disparos',
            data: values,
            backgroundColor: 'rgba(75, 192, 192, 0.2)',
            borderColor: 'rgba(75, 192, 192, 1)',
            borderWidth: 1,
          },
        ],
      };
    },
    fetchAllData() {
      const { from, to, groupBy } = this;
      const payload = { from, to };

      if (groupBy) {
        payload.groupBy = groupBy;
      }

      this.$store.dispatch('fetchTriggersReport', payload);
      this.$store.dispatch('fetchTriggersMetric', payload);
    },
    onDateRangeChange({ from, to }) {
      this.from = from;
      this.to = to;

      this.fetchAllData();
    },
    onBusinessHoursToggle(value) {
      this.businessHours = value;
      this.fetchAllData();
    },
    onGroupByFilterChange(payload = {}) {
      const { id } = payload;
      this.groupBy = GROUP_BY_FILTER[id].period;

      this.fetchAllData();
    },
  },
};
</script>
