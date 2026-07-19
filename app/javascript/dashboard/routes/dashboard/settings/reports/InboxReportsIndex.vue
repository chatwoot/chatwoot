<script setup>
import SummaryReportsPage from './components/SummaryReportsPage.vue';
</script>

<template>
  <SummaryReportsPage
    :header-title="$t('INBOX_REPORTS.HEADER')"
    :header-description="$t('INBOX_REPORTS.DESCRIPTION')"
    :download-label="$t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS')"
    action-key="summaryReports/fetchInboxSummaryReports"
    getter-key="inboxes/getInboxes"
    fetch-items-key="inboxes/get"
    summary-key="summaryReports/getInboxSummaryReports"
    type="inbox"
  />
</template>
