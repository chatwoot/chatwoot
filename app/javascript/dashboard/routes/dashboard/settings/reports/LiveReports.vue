<script setup>
import { ref } from 'vue';

import ReportHeader from './components/ReportHeader.vue';
import ConversationHeatmapContainer from './components/heatmaps/ConversationHeatmapContainer.vue';
import ResolutionHeatmapContainer from './components/heatmaps/ResolutionHeatmapContainer.vue';
import AgentLiveReportContainer from './components/AgentLiveReportContainer.vue';
import TeamLiveReportContainer from './components/TeamLiveReportContainer.vue';
import StatsLiveReportsContainer from './components/StatsLiveReportsContainer.vue';
import V4Button from 'dashboard/components-next/button/Button.vue';

const overviewReportsRef = ref(null);

const onDownloadClick = () => {
  overviewReportsRef.value.downloadReports();
};
</script>

<template>
  <ReportHeader :header-title="$t('OVERVIEW_REPORTS.HEADER')">
    <V4Button
      :label="$t('OVERVIEW_REPORTS.DOWNLOAD')"
      icon="i-ph-download-simple"
      size="sm"
      @click="onDownloadClick"
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
