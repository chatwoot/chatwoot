<template>
  <div class="column overflow-auto flex-1 pt-4">
    <!-- NEW ONE -->
    <metric-card
      :is-live="false"
      header="All agents overview"
      :show-download-button="true"
      :download-filters="filters"
      :download-type="'overview'"
      :is-loading="uiFlags.isAgentOverviewReportsLoading"
      loading-message="Loading metrics"
    >
      <woot-summary-reports
        key="agent-summary-reports"
        class="!p-0"
        type="agent"
        getter-key="agents/getAgents"
        attribute-key="team_id"
        action-key="summaryReports/fetchCustomAgentOverviewReports"
        summary-key="summaryReports/getCustomAgentOverviewReports"
        :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
        :show-advanced-filters="true"
        :agent-table-type="'overview'"
        @filter-change="handleFilterChange"
      />
    </metric-card>
    <metric-card
      :is-live="false"
      header="Agent wise conversation states"
      :show-download-button="true"
      :download-filters="filters"
      :download-type="'conversationStates'"
      :is-loading="uiFlags.isAgentConversationStatesReportsLoading"
      loading-message="Loading metrics"
    >
      <woot-summary-reports
        key="agent-summary-reports"
        class="!p-0"
        type="agent"
        getter-key="agents/getAgents"
        attribute-key="team_id"
        action-key="summaryReports/fetchCustomAgentConversationStatesReports"
        summary-key="summaryReports/getCustomAgentConversationStatesReports"
        :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
        :show-advanced-filters="true"
        :agent-table-type="'conversationStates'"
        @filter-change="handleFilterChange"
      />
    </metric-card>
    <!-- NEW ONE END -->
    <!-- <metric-card :is-live="false" header="All agents overview">
      <woot-summary-reports
        key="agent-summary-reports"
        class="!p-0"
        type="agent"
        getter-key="agents/getAgents"
        attribute-key="team_id"
        action-key="summaryReports/fetchAgentSummaryReports"
        summary-key="summaryReports/getAgentSummaryReports"
        :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
      />
    </metric-card>
    <metric-card
      :is-live="false"
      header="Agent-wise reports"
      class="overflow-visible"
    >
      <woot-reports
        key="agent-reports"
        :show-download-button="false"
        class="!p-0"
        type="agent"
        getter-key="agents/getAgents"
        action-key="agents/get"
      />
    </metric-card> -->
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
