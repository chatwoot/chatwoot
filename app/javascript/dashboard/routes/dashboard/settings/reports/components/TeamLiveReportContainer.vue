<script setup>
import { onMounted } from 'vue';

import MetricCard from './overview/MetricCard.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';
import TeamTable from './overview/TeamTable.vue';

const store = useStore();

const uiFlags = useMapGetter('getOverviewUIFlags');
const teamConversationMetric = useMapGetter('getTeamConversationMetric');
const teams = useMapGetter('teams/getTeams');

const fetchData = () => store.dispatch('fetchTeamConversationMetric');

const { startRefetching } = useLiveRefresh(fetchData);

onMounted(() => {
  store.dispatch('teams/get');
  fetchData();
  startRefetching();
});
</script>

<template>
  <div class="flex flex-row flex-wrap max-w-full">
    <MetricCard :header="$t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.HEADER')">
      <TeamTable
        :teams="teams"
        :team-metrics="teamConversationMetric"
        :is-loading="uiFlags.isFetchingTeamConversationMetric"
      />
    </MetricCard>
  </div>
</template>
