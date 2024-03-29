<template>
  <div class="column overflow-auto">
    <metric-card :is-live="false" header="All agents overview">
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
    </metric-card>
  </div>
</template>

<script>
import WootSummaryReports from './components/WootSummaryReports.vue';
import MetricCard from './components/overview/MetricCard.vue';
import WootReports from './components/WootReports.vue';

export default {
  components: {
    WootReports,
    MetricCard,
    WootSummaryReports,
  },
};
</script>
