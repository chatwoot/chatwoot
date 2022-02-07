<template>
  <woot-reports
    key="agent-reports"
    type="agent"
    getter-key="agents/getAgents"
    action-key="agents/get"
    :download-button-label="$t('REPORT.DOWNLOAD_AGENT_REPORTS')"
  />
</template>

<script>
import WootReports from './components/WootReports';

export default {
  components: {
    WootReports,
  },
};
</script>
