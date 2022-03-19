<template>
  <woot-reports
    key="inbox-reports"
    type="inbox"
    getter-key="inboxes/getInboxes"
    action-key="inboxes/get"
    :download-button-label="$t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS')"
  />
</template>

<script>
import WootReports from './components/WootReports.vue';

export default {
  components: {
    WootReports,
  },
};
</script>
