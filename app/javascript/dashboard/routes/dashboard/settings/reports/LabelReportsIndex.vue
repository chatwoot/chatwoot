<script setup>
import SummaryReportsPage from './components/SummaryReportsPage.vue';
</script>

<template>
  <SummaryReportsPage
    :header-title="$t('LABEL_REPORTS.HEADER')"
    :header-description="$t('LABEL_REPORTS.DESCRIPTION')"
    :download-label="$t('LABEL_REPORTS.DOWNLOAD_LABEL_REPORTS')"
    action-key="summaryReports/fetchLabelSummaryReports"
    getter-key="labels/getLabels"
    fetch-items-key="labels/get"
    summary-key="summaryReports/getLabelSummaryReports"
    type="label"
  />
</template>
