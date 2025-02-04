<template>
  <div class="column overflow-auto flex-1 pt-4 pb-40">
    <metric-card
      :is-live="false"
      header="Agent wise Call Overview"
      :download-filters="filters"
      :download-type="'callOverview'"
    >
      <woot-summary-reports
        key="agent-call-overview-reports"
        class="!p-0"
        type="agent"
        getter-key="agents/getAgents"
        attribute-key="team_id"
        action-key="summaryReports/fetchCustomAgentCallOverviewReports"
        summary-key="summaryReports/getCustomAgentCallOverviewReports"
        :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
        :show-advanced-filters="true"
        :agent-table-type="'callOverview'"
        @filter-change="handleFilterChange"
      />
    </metric-card>

    <metric-card
      :is-live="false"
      header="Inbound Call Analytics"
      :download-filters="filters"
      :download-type="'inboundCallOverview'"
    >
      <woot-summary-reports
        key="agent-call-overview-reports"
        class="!p-0"
        type="agent"
        getter-key="agents/getAgents"
        attribute-key="team_id"
        action-key="summaryReports/fetchCustomAgentInboundCallOverviewReports"
        summary-key="summaryReports/getCustomAgentInboundCallOverviewReports"
        :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
        :show-advanced-filters="true"
        :agent-table-type="'inboundCallOverview'"
        @filter-change="handleFilterChange"
      />
    </metric-card>
  </div>
</template>

<script>
import WootSummaryReports from './components/WootSummaryReports.vue';
import MetricCard from './components/overview/MetricCard.vue';
// import WootReports from './components/WootReports.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    // WootReports,
    MetricCard,
    WootSummaryReports,
  },
  data() {
    return {
      filters: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'summaryReports/getUiFlags',
    }),
  },
  created() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    handleFilterChange(filter) {
      this.filters = filter;
    },
  },
};
</script>
