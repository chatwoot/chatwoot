<script setup>
import SummaryReportsPage from './components/SummaryReportsPage.vue';
</script>

<template>
  <SummaryReportsPage
    :header-title="$t('AGENT_REPORTS.HEADER')"
    :header-description="$t('AGENT_REPORTS.DESCRIPTION')"
    :download-label="$t('AGENT_REPORTS.DOWNLOAD_AGENT_REPORTS')"
    action-key="summaryReports/fetchAgentSummaryReports"
    getter-key="agents/getAgents"
    fetch-items-key="agents/get"
    summary-key="summaryReports/getAgentSummaryReports"
    type="agent"
  />
</template>
