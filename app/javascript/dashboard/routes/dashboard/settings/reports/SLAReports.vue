<template>
  <div class="flex flex-col flex-1 gap-6 p-4 overflow-auto font-inter">
    <SLAMetrics
      :hit-rate="slaMetrics.hitRate"
      :no-of-breaches="slaMetrics.numberOfSLABreaches"
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
export default {
  name: 'SLAReports',
  components: {
    SLAMetrics,
    SLATable,
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
