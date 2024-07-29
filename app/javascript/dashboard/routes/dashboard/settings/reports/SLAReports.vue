<template>
  <div class="flex flex-col flex-1 gap-6 px-4 pt-4 overflow-auto">
    <SLAReportFilters @filter-change="onFilterChange" />
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="arrow-download"
      @click="downloadReports"
    >
      {{ $t('SLA_REPORTS.DOWNLOAD_SLA_REPORTS') }}
    </woot-button>
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
import { useAlert } from 'dashboard/composables';
import SLAMetrics from './components/SLA/SLAMetrics.vue';
import SLATable from './components/SLA/SLATable.vue';
import SLAReportFilters from './components/SLA/SLAReportFilters.vue';
import { generateFileName } from 'dashboard/helper/downloadHelper';
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
      activeFilter: {
        from: 0,
        to: 0,
        assigned_agent_id: null,
        inbox_id: null,
        team_id: null,
        sla_policy_id: null,
        label_list: null,
      },
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
    this.$store.dispatch('agents/get');
    this.$store.dispatch('inboxes/get');
    this.$store.dispatch('teams/get');
    this.$store.dispatch('labels/get');
    this.$store.dispatch('sla/get');
    this.fetchSLAMetrics();
    this.fetchSLAReports();
  },
  methods: {
    fetchSLAReports({ pageNumber } = {}) {
      this.$store.dispatch('slaReports/get', {
        page: pageNumber || this.pageNumber,
        ...this.activeFilter,
      });
    },
    fetchSLAMetrics() {
      this.$store.dispatch('slaReports/getMetrics', this.activeFilter);
    },
    onPageChange(pageNumber) {
      this.fetchSLAReports({ pageNumber });
    },
    onFilterChange(params) {
      this.activeFilter = params;
      this.fetchSLAReports();
      this.fetchSLAMetrics();
    },
    downloadReports() {
      const type = 'sla';
      try {
        this.$store.dispatch('slaReports/download', {
          fileName: generateFileName({ type, to: this.activeFilter.to }),
          ...this.activeFilter,
        });
      } catch (error) {
        useAlert(this.$t('SLA_REPORTS.DOWNLOAD_FAILED'));
      }
    },
  },
};
</script>
