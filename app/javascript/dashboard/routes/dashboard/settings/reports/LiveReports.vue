<script setup>
import { onMounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store.js';

import ReportHeader from './components/ReportHeader.vue';
import ConversationHeatmapContainer from './components/heatmaps/ConversationHeatmapContainer.vue';
import ResolutionHeatmapContainer from './components/heatmaps/ResolutionHeatmapContainer.vue';
import AgentLiveReportContainer from './components/AgentLiveReportContainer.vue';
import TeamLiveReportContainer from './components/TeamLiveReportContainer.vue';
import StatsLiveReportsContainer from './components/StatsLiveReportsContainer.vue';
import TopIntentsCard from 'dashboard/components-next/captain/pageComponents/overview/TopIntentsCard.vue';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const store = useStore();
const assistants = useMapGetter('captainAssistants/getRecords');

const selectedAssistantId = ref(null);
const intents = ref(null);
const isFetchingIntents = ref(false);

// Default to the first available assistant once the list loads.
watch(
  assistants,
  list => {
    if (!list?.length) return;
    if (
      !selectedAssistantId.value ||
      !list.some(assistant => assistant.id === selectedAssistantId.value)
    ) {
      selectedAssistantId.value = list[0].id;
    }
  },
  { immediate: true }
);

const fetchIntents = async () => {
  if (!selectedAssistantId.value) return;
  isFetchingIntents.value = true;
  intents.value = null;
  try {
    const { data } = await CaptainAssistant.getIntents({
      assistantId: selectedAssistantId.value,
      range: '7',
    });
    intents.value = data;
  } catch {
    intents.value = { total_intents: 0, total_questions: 0, intents: [] };
  } finally {
    isFetchingIntents.value = false;
  }
};

watch(selectedAssistantId, fetchIntents);

onMounted(() => {
  store.dispatch('captainAssistants/get');
});
</script>

<template>
  <ReportHeader :header-title="$t('OVERVIEW_REPORTS.HEADER')" />
  <div class="flex flex-col gap-4 pb-6">
    <StatsLiveReportsContainer />
    <ConversationHeatmapContainer />
    <ResolutionHeatmapContainer />
    <AgentLiveReportContainer />
    <TeamLiveReportContainer />
    <TopIntentsCard
      v-if="assistants && assistants.length > 0"
      :intents="
        intents ?? { total_intents: 0, total_questions: 0, intents: [] }
      "
      :loading="isFetchingIntents"
    />
  </div>
</template>
