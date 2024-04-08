<template>
  <div class="flex flex-col flex-1 px-4 pt-4 overflow-auto">
    <SLAReportFilters @filter-change="onFilterChange" />
    <div class="flex flex-col gap-6">
      <SLAMetrics
        :hit-rate="slaMetrics.hitRate"
        :no-of-breaches="slaMetrics.numberOfSLAMisses"
        :no-of-conversations="slaMetrics.numberOfConversations"
        :is-loading="uiFlags.isFetchingMetrics"
      />
      <SLATable
        :sla-reports="slaReports"
        :is-loading="uiFlags.isFetching"
        :current-page="Number(slaMeta.currentPage)"
        :total-count="Number(slaMeta.count)"
        @page-change="onPageChange"
      />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import SLAMetrics from './components/SLA/SLAMetrics.vue';
import SLATable from './components/SLA/SLATable.vue';
import SLAReportFilters from './components/SLA/SLAReportFilters.vue';

export default {
  name: 'SLAReports',
  components: {
    SLAMetrics,
    SLATable,
    SLAReportFilters,
  },
  data() {
    return {
      pageNumber: 1,
      from: 0,
      to: 0,
    };
  },
  computed: {
    ...mapGetters({
      slaReports: 'slaReports/getAll',
      slaMetrics: 'slaReports/getMetrics',
      slaMeta: 'slaReports/getMeta',
      uiFlags: 'slaReports/getUIFlags',
    }),
  },
  mounted() {
    this.fetchSLAMetrics();
    this.fetchSLAReports();
  },
  methods: {
    fetchSLAReports({ pageNumber } = {}) {
      this.$store.dispatch('slaReports/get', {
        page: pageNumber || this.pageNumber,
        from: this.from,
        to: this.to,
      });
    },
    fetchSLAMetrics() {
      this.$store.dispatch('slaReports/getMetrics', {
        from: this.from,
        to: this.to,
      });
    },
    onPageChange(pageNumber) {
      this.fetchSLAReports({ pageNumber });
    },
    onFilterChange({ from, to }) {
      this.from = from;
      this.to = to;
      this.fetchSLAReports();
      this.fetchSLAMetrics();
    },
  },
};
</script>
