<script setup>
import { ref } from 'vue';
import ReportHeader from './components/ReportHeader.vue';
import SummaryReports from './components/SummaryReports.vue';
import DownloadDropdown from 'dashboard/components/DownloadDropdown.vue';
import { useReportDownloadOptions } from 'dashboard/composables/useReportDownloadOptions';

const summarReportsRef = ref(null);
const { downloadOptions } = useReportDownloadOptions();
const handleDownload = format => {
  summarReportsRef.value.downloadReports(format);
};
</script>

<template>
  <ReportHeader
    :header-title="$t('INBOX_REPORTS.HEADER')"
    :header-description="$t('INBOX_REPORTS.DESCRIPTION')"
  >
    <DownloadDropdown
      :label="$t('INBOX_REPORTS.DOWNLOAD_INBOX_REPORTS')"
      :options="downloadOptions"
      @select="handleDownload"
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
