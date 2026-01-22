<script setup>
import { ref } from 'vue';

import ReportHeader from './components/ReportHeader.vue';
import ConversationHeatmapContainer from './components/heatmaps/ConversationHeatmapContainer.vue';
import ResolutionHeatmapContainer from './components/heatmaps/ResolutionHeatmapContainer.vue';
import AgentLiveReportContainer from './components/AgentLiveReportContainer.vue';
import TeamLiveReportContainer from './components/TeamLiveReportContainer.vue';
import StatsLiveReportsContainer from './components/StatsLiveReportsContainer.vue';

import DownloadDropdown from 'dashboard/components/DownloadDropdown.vue';
import { useReportDownloadOptions } from 'dashboard/composables/useReportDownloadOptions';

const overviewReportsRef = ref(null);
const { downloadOptions } = useReportDownloadOptions();

const handleDownload = option => {
  const format = option?.value || option || 'csv';
  overviewReportsRef.value?.downloadReports(format);
};
</script>

<template>
  <ReportHeader :header-title="$t('OVERVIEW_REPORTS.HEADER')">
    <DownloadDropdown
      :label="$t('OVERVIEW_REPORTS.DOWNLOAD')"
      :options="downloadOptions"
      @select="handleDownload"
    />
  </ReportHeader>

  <div class="flex flex-col gap-4 pb-6">
    <StatsLiveReportsContainer ref="overviewReportsRef" />
    <ConversationHeatmapContainer />
    <ResolutionHeatmapContainer />
    <AgentLiveReportContainer />
    <TeamLiveReportContainer />
  </div>
</template>
