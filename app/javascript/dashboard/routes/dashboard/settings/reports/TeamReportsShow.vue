<script setup>
import WootReports from './components/WootReports.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const hasBackButton = true;
import { useRoute } from 'vue-router';
const route = useRoute();

import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';
const getters = useStoreGetters();

const team = computed(() =>
  getters['teams/getTeamById'].value(route.params.id)
);
</script>

<template>
  <WootReports
    v-if="team.id"
    :key="team.id"
    type="team"
    getter-key="teams/getTeams"
    action-key="teams/get"
    :selected-item="team"
    :download-button-label="$t('TEAM_REPORTS.DOWNLOAD_TEAM_REPORTS')"
    :report-title="$t('TEAM_REPORTS.HEADER')"
    :has-back-button
  />
  <Spinner v-else />
</template>
