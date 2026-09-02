<script setup>
import ReportHeader from './components/ReportHeader.vue';
import ConversationHeatmapContainer from './components/heatmaps/ConversationHeatmapContainer.vue';
import ConversationIntervalContainer from './components/interval/ConversationIntervalContainer.vue';
import ResolutionHeatmapContainer from './components/heatmaps/ResolutionHeatmapContainer.vue';
import AgentRankingContainer from './components/productivity/AgentRankingContainer.vue';
import AgentDailyContainer from './components/productivity/AgentDailyContainer.vue';
import AgentLiveReportContainer from './components/AgentLiveReportContainer.vue';
import TeamLiveReportContainer from './components/TeamLiveReportContainer.vue';
import StatsLiveReportsContainer from './components/StatsLiveReportsContainer.vue';
</script>

<template>
  <ReportHeader :header-title="$t('OVERVIEW_REPORTS.HEADER')" />
  <div class="flex flex-col gap-4 pb-6">
    <StatsLiveReportsContainer />
    <ConversationHeatmapContainer />
    <ConversationIntervalContainer />
    <ResolutionHeatmapContainer />
    <AgentRankingContainer />
    <AgentDailyContainer />
    <AgentLiveReportContainer />
    <TeamLiveReportContainer />
  </div>
</template>
