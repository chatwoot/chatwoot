<template>
  <div class="overflow-auto">
    <metric-card :is-live="false" header="All teams overview">
      <team-list-table />
    </metric-card>
    <metric-card
      :is-live="false"
      header="Team wise reports"
      class="overflow-visible"
    >
      <woot-reports
        key="team-reports"
        class="!p-0"
        type="team"
        getter-key="teams/getTeams"
        action-key="teams/get"
        :download-button-label="$t('TEAM_REPORTS.DOWNLOAD_TEAM_REPORTS')"
      />
    </metric-card>
  </div>
</template>

<script>
import TeamListTable from './components/AggregateTables/TeamListTable.vue';
import WootReports from './components/WootReports.vue';
import MetricCard from './components/overview/MetricCard.vue';

export default {
  components: {
    WootReports,
    MetricCard,
    TeamListTable,
  },
};
</script>
