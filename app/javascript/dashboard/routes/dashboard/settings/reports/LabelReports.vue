<template>
  <woot-reports
    type="label"
    getter-key="labels/getLabels"
    action-key="labels/get"
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
