<script setup>
import WootReports from './components/WootReports.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useRoute } from 'vue-router';
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';

const hasBackButton = true;
const route = useRoute();
const getters = useStoreGetters();

const agent = computed(() =>
  getters['agents/getAgentById'].value(route.params.id)
);
</script>

<template>
  <WootReports
    v-if="agent.id"
    :key="agent.id"
    type="agent"
    getter-key="agents/getAgents"
    action-key="agents/get"
    :selected-item="agent"
    :download-button-label="$t('AGENT_REPORTS.DOWNLOAD_AGENT_REPORTS')"
    :report-title="$t('AGENT_REPORTS.HEADER')"
    :has-back-button
  />
  <Spinner v-else />
</template>
