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
    :header-title="$t('LABEL_REPORTS.HEADER')"
    :header-description="$t('LABEL_REPORTS.DESCRIPTION')"
  >
    <V4Button
      :label="$t('LABEL_REPORTS.DOWNLOAD_LABEL_REPORTS')"
      icon="i-ph-download-simple"
      size="sm"
      @click="onDownloadClick"
    />
  </ReportHeader>

  <SummaryReports
    ref="summarReportsRef"
    action-key="summaryReports/fetchLabelSummaryReports"
    getter-key="labels/getLabels"
    fetch-items-key="labels/get"
    summary-key="summaryReports/getLabelSummaryReports"
    type="label"
  />
</template>
