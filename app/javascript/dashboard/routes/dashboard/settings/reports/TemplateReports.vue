<template>
  <woot-template-reports
    key="template-reports"
    type="template"
    getter-key="inboxes/getAllTemplates"
    action-key="agents/get"
    :download-button-label="$t('TEMPLATE_REPORTS.DOWNLOAD_TEMPLATE_REPORTS')"
  />
</template>

<script>
import WootTemplateReports from './components/WootTemplateReports.vue';

export default {
  components: {
    WootTemplateReports,
  },
};
</script>
