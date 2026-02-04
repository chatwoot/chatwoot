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
    :header-title="$t('AGENT_REPORTS.HEADER')"
    :header-description="$t('AGENT_REPORTS.DESCRIPTION')"
  >
    <DownloadDropdown
      :label="$t('AGENT_REPORTS.DOWNLOAD_AGENT_REPORTS')"
      :options="downloadOptions"
      @select="handleDownload"
    />
  </ReportHeader>

  <SummaryReports
    ref="summarReportsRef"
    action-key="summaryReports/fetchAgentSummaryReports"
    getter-key="agents/getAgents"
    fetch-items-key="agents/get"
    summary-key="summaryReports/getAgentSummaryReports"
    type="agent"
  />
</template>
