<script setup>
import { ref } from 'vue';
import ReportHeader from './components/ReportHeader.vue';
import SummaryReports from './components/SummaryReports.vue';
import V4Button from 'dashboard/components-next/button/Button.vue';

const summarReportsRef = ref(null);

const onDownloadClick = () => {
  summarReportsRef.value.downloadReports();
};
</script>

<template>
  <ReportHeader
    :header-title="$t('INBOX_REPORTS.HEADER')"
    :header-description="$t('INBOX_REPORTS.DESCRIPTION')"
  >
    <V4Button
      :label="$t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS')"
      icon="i-ph-download-simple"
      size="sm"
      @click="onDownloadClick"
    />
  </ReportHeader>

  <SummaryReports
    ref="summarReportsRef"
    action-key="summaryReports/fetchInboxSummaryReports"
    getter-key="inboxes/getInboxes"
    fetch-items-key="inboxes/get"
    summary-key="summaryReports/getInboxSummaryReports"
    type="inbox"
  />
</template>
