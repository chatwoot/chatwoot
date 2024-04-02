<template>
  <div class="flex flex-col flex-1 gap-6 p-4 overflow-auto font-inter">
    <!-- <SLA-filters /> -->
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
// import SLAFilters from './components/SLA/SLAFilters.vue';
export default {
  name: 'SLAReports',
  components: {
    SLAMetrics,
    SLATable,
    // SLAFilters,
  },
  data() {
    return {
      pageNumber: 1,
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
    this.$store.dispatch('slaReports/getMetrics');
    this.fetchSLAReports();
  },
  methods: {
    fetchSLAReports({ pageNumber } = {}) {
      this.$store.dispatch('slaReports/get', {
        page: pageNumber || this.pageNumber,
      });
    },
    onPageChange(pageNumber) {
      this.fetchSLAReports({ pageNumber });
    },
  },
};
</script>
