<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';

import WootReports from './components/WootReports.vue';

const route = useRoute();
const store = useStore();

const agentId = computed(() => route.params.id);

const agent = computed(() => {
  if (!agentId.value) return null;
  return store.getters['agents/getAgentById'](agentId.value);
});

onMounted(() => {
  store.dispatch('agents/get');
});
</script>

<template>
  <WootReports
    :key="agent?.id || 'empty-agent'"
    type="agent"
    getter-key="agents/getAgents"
    action-key="agents/get"
    :selected-item="agent"
    :download-button-label="$t('AGENT_REPORTS.DOWNLOAD_AGENT_REPORTS')"
    :report-title="$t('AGENT_REPORTS.HEADER')"
    has-back-button
  />
</template>
