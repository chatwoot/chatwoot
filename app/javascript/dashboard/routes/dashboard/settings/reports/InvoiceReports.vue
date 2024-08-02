<template>
  <div class="flex-1 overflow-auto p-4">
    <report-filters
      type="invoices"
      :group-by-filter-items-list="groupByFilterItemsList"
      @date-range-change="onDateRangeChange"
      @business-hours-toggle="onBusinessHoursToggle"
      @group-by-filter-change="onGroupByFilterChange"
    />
    <div class="row">
      <metric-card
        :is-live="false"
        :is-loading="false"
        :header="$t('INVOICE_REPORTS.SUBTITLE')"
        :loading-message="$t('REPORT.LOADING_CHART')"
      >
        <template v-if="conversationMetrics.length > 0">
          <div
            v-for="(metric, name, index) in conversationMetrics"
            :key="index"
            class="metric-content column"
          >
            <h3 class="heading">{{ name }}</h3>
            <p class="metric">{{ metric }}</p>
          </div>
        </template>
        <template v-else>
          <div class="flex items-center justify-center w-full">
            <span class="text-sm text-slate-600">
              {{ $t('REPORT.NO_ENOUGH_DATA') }}
            </span>
          </div>
        </template>
      </metric-card>
    </div>
    <div class="row">
      <metric-card :header="$t('INVOICE_REPORTS.GRAPH_TITLE')">
        <div class="metric-content column">
          <woot-loading-state
            v-if="false"
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
import MetricCard from './components/overview/MetricCard.vue';
import ReportFilters from './components/ReportFilters.vue';
import { mapGetters } from 'vuex';

export default {
  name: 'InvoiceReports',
  components: {
    MetricCard,
    ReportFilters,
  },
  data: () => ({
    chartData: {
      labels: [],
      datasets: [],
    },
    from: Math.floor(new Date().setMonth(new Date().getMonth() - 6) / 1000),
    to: Math.floor(Date.now() / 1000),
    groupBy: null,
  }),
  computed: {
    ...mapGetters({}),
    groupByFilterItemsList() {
      return this.$t('REPORT.GROUP_BY_YEAR_OPTIONS');
    },
    conversationMetrics() {
      let metric = {};
      return metric;
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    onGroupByFilterChange(payload) {
      this.groupBy = payload.id;
      this.fetchAllData();
    },
    onBusinessHoursToggle(value) {
      this.businessHours = value;
      this.fetchAllData();
    },
    onDateRangeChange({ from, to }) {
      this.from = from;
      this.to = to;

      this.fetchAllData();
    },
    fetchAllData() {
      const { from, to, groupBy } = this;
      const payload = { from, to };

      if (groupBy) {
        payload.groupBy = groupBy;
      }

      this.$store.dispatch('fetchInvoicesReport', payload);
      this.$store.dispatch('fetchInvoicesMetric', payload);
    },
  },
};
</script>
