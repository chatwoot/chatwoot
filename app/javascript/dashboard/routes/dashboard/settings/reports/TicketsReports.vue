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
        :is-loading="ticketsUIFlags.isFetching"
        :header="$t('TICKETS_REPORTS.SUBTITLE')"
        :loading-message="$t('REPORT.LOADING_CHART')"
      >
        <template v-if="!ticketsUIFlags.isFetching">
          <div
            v-for="(metric, name, index) in ticketsMetrics"
            :key="index"
            class="metric-content column"
          >
            <h3 class="heading">{{ name }}</h3>
            <p class="metric">{{ metric }}</p>
          </div>
        </template>
      </metric-card>
    </div>
    <div class="row">
      <metric-card :header="$t('TICKETS_REPORTS.GRAPH_TITLE')">
        <!-- list of agents per tickets -->
        <div class="metric-content column">
          <woot-loading-state
            v-if="ticketsUIFlags.isFetching"
            class="text-xs"
            :message="$t('REPORT.LOADING_CHART')"
          />
          <div v-else class="flex items-center justify-center">
            <virtual-list
              ref="ticketVirtualList"
              :data-key="'id'"
              :data-sources="ticketsReport"
              :data-component="itemComponent"
              class="w-full overflow-auto h-1/2"
              footer-tag="div"
            />
          </div>
        </div>
      </metric-card>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { TICKETS_SUMMARY_METRICS } from './constants';

import VirtualList from 'vue-virtual-scroll-list';
import MetricCard from './components/overview/MetricCard';
import ReportFilters from './components/ReportFilters';
import TicketsPerAgentComponent from 'dashboard/routes/dashboard/tickets/components/TicketsPerAgentComponent';

export default {
  name: 'TicketsReports',
  components: {
    MetricCard,
    ReportFilters,
    VirtualList,
    // eslint-disable-next-line vue/no-unused-components
    TicketsPerAgentComponent,
  },
  data: () => ({
    itemComponent: TicketsPerAgentComponent,
    from: Math.floor(new Date().setMonth(new Date().getMonth() - 6) / 1000),
    to: Math.floor(Date.now() / 1000),
    groupBy: null,
  }),
  computed: {
    ...mapGetters({
      ticketsReport: 'ticketsReport/getTicketsReport',
      ticketsSummary: 'ticketsReport/getTicketsSummary',
      ticketsUIFlags: 'ticketsReport/getUIFlags',
    }),
    groupByFilterItemsList() {
      return this.$t('REPORT.GROUP_BY_YEAR_OPTIONS');
    },
    ticketsMetrics() {
      let metric = {};
      Object.keys(this.ticketsSummary || {}).forEach(key => {
        const metricName = this.$t(
          'TICKETS_REPORTS.METRICS.' + TICKETS_SUMMARY_METRICS[key] + '.NAME'
        );
        metric[metricName] = this.ticketsSummary[key];
      });
      return metric;
    },
  },
  created() {
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

      this.$store.dispatch('ticketsReport/getAll', payload);
      this.$store.dispatch('ticketsReport/getSummary', payload);
    },
  },
};
</script>
