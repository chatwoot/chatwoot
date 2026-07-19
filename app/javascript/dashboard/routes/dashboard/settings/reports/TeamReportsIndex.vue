<script setup>
import SummaryReportsPage from './components/SummaryReportsPage.vue';
</script>

<template>
  <SummaryReportsPage
    :header-title="$t('TEAM_REPORTS.HEADER')"
    :header-description="$t('TEAM_REPORTS.DESCRIPTION')"
    :download-label="$t('TEAM_REPORTS.DOWNLOAD_TEAM_REPORTS')"
    action-key="summaryReports/fetchTeamSummaryReports"
    getter-key="teams/getTeams"
    fetch-items-key="teams/get"
    summary-key="summaryReports/getTeamSummaryReports"
    type="team"
  />
</template>
