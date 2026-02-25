<script setup>
import WootReports from './components/WootReports.vue';
</script>

<template>
  <WootReports
    key="agent-reports"
    type="agent"
    getter-key="agents/getAgents"
    action-key="agents/get"
    :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
    :report-title="$t('AGENT_REPORTS.HEADER')"
  />
</template>
