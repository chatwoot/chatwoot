<template>
  <woot-reports
    key="inbox-reports"
    type="inbox"
    getter-key="inboxes/getInboxes"
    action-key="inboxes/get"
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
