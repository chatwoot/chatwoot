<template>
  <div class="flex-1 overflow-auto p-4">
    <report-filters
      type="triggers"
      :group-by-filter-items-list="groupByfilterItemsList"
      @date-range-change="onDateRangeChange"
      @business-hours-toggle="onBusinessHoursToggle"
    />
    <div class="row">
      <metric-card
        :is-live="false"
        :is-loading="triggersMetric.isFetchingMetrics"
        header="Relatório de Disparos"
        loading-message="carregando..."
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
      <metric-card header="Gráfico">
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
import { TRIGGERS_METRICS } from './constants';
import MetricCard from './components/overview/MetricCard.vue';
import ReportFilters from './components/ReportFilters.vue';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import { GROUP_BY_FILTER } from './constants';

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
      groupBy: GROUP_BY_FILTER[1],
      groupByfilterItemsList: this.$t('REPORT.GROUP_BY_DAY_OPTIONS'),
    };
  },
  computed: {
    ...mapGetters({
      triggersMetric: 'getTriggersReport',
    }),
    conversationMetrics() {
      let metric = {};
      Object.keys(this.triggersMetric.metrics || {}).forEach(key => {
        const metricName = TRIGGERS_METRICS[key]; // TODO: change to translate correctly
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
    prepareChartData() {
      const data = this.triggersMetric.data || [];
      const labels = data.map(item =>
        format(fromUnixTime(item.timestamp), 'dd-MMM')
      );
      const values = data.map(item => item.value);
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
      this.$store.dispatch('fetchTriggersReport', { from, to, groupBy });
      this.$store.dispatch('fetchTriggersMetric');
    },
    onDateRangeChange({ from, to, groupBy }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.fetchAllData();
    },
    onBusinessHoursToggle(value) {
      this.businessHours = value;
      this.fetchAllData();
    },
    onGroupByFilterChange(payload) {
      // eslint-disable-next-line no-console
      console.log('onGroupByFilterChange', payload);
      this.groupBy = GROUP_BY_FILTER[payload.id];
      this.fetchAllData();
    },
  },
};
</script>
