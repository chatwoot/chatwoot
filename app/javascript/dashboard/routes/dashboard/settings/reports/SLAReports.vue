<template>
  <div class="flex flex-col flex-1 gap-6 p-4 overflow-auto font-inter">
    <SLAReportFilters @filter-change="onFilterChange" />
    <SLAMetrics
      :hit-rate="slaMetrics.hitRate"
      :no-of-breaches="slaMetrics.numberOfSLABreaches"
      :is-loading="uiFlags.isLoading"
    />
    <SLATable
      :sla-reports="slaReports"
      :current-page="Number(slaMeta.currentPage)"
      :total-count="Number(slaMeta.count)"
      @page-change="onPageChange"
    />
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
