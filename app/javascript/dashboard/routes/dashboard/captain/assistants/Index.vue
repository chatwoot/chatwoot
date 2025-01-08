<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import AssistantCard from 'dashboard/components-next/captain/assistant/AssistantCard.vue';
const store = useStore();

const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const assistants = useMapGetter('captainAssistants/getCaptainAssistants');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

onMounted(() => {
  store.dispatch('captainAssistants/get');
});
</script>

<template>
  <PageLayout header-title="Assistants" button-label="Add a new assistant">
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="assistants.length" class="flex flex-col gap-4">
      <AssistantCard
        v-for="assistant in assistants"
        :id="assistant.id"
        :key="assistant.id"
        :name="assistant.name"
        :description="assistant.description"
        :updated-at="assistant.updated_at || assistant.created_at"
        :created-at="assistant.created_at"
      />
    </div>

    <div v-else>{{ 'No assistants found' }}</div>
  </PageLayout>
</template>
