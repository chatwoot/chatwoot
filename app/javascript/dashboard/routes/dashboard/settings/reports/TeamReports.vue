<template>
  <div class="column overflow-auto">
    <metric-card :is-live="false" header="All teams overview">
      <woot-summary-reports
        key="team-reports"
        class="!p-0"
        type="team"
        getter-key="teams/getTeams"
        attribute-key="team_id"
        action-key="summaryReports/fetchTeamSummaryReports"
        summary-key="summaryReports/getTeamSummaryReports"
        :download-button-label="$t('TEAM_REPORTS.DOWNLOAD_TEAM_REPORTS')"
      />
    </metric-card>
    <metric-card
      :is-live="false"
      header="Team-wise reports"
      class="overflow-visible"
    >
      <woot-reports
        key="team-reports"
        :show-download-button="false"
        class="!p-0"
        type="team"
        getter-key="teams/getTeams"
        action-key="teams/get"
      />
    </metric-card>
  </div>
</template>

<script>
import WootSummaryReports from './components/WootSummaryReports.vue';
import MetricCard from './components/overview/MetricCard.vue';
import WootReports from './components/WootReports.vue';

export default {
  components: {
    WootReports,
    MetricCard,
    WootSummaryReports,
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
};
</script>
