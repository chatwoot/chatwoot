<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import AssistantCard from 'dashboard/components-next/captain/assistant/AssistantCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/assistant/DeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const store = useStore();

const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const assistants = useMapGetter('captainAssistants/getCaptainAssistants');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedAssistant = ref(null);
const deleteDialog = ref(null);

const handleDelete = () => {
  deleteDialog.value.dialogRef.open();
};
const handleAction = ({ action, id }) => {
  selectedAssistant.value = assistants.value.find(
    assistant => id === assistant.id
  );

  if (action === 'delete') {
    handleDelete();
  }
};

onMounted(() => store.dispatch('captainAssistants/get'));
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.HEADER')"
    :button-label="$t('CAPTAIN.ASSISTANTS.ADD_NEW')"
    :show-pagination-footer="false"
  >
    <div
      v-if="isFetching"
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
        @action="handleAction"
      />
    </div>

    <div v-else>{{ 'No assistants found' }}</div>

    <DeleteDialog
      ref="deleteDialog"
      :entity="selectedAssistant"
      type="Assistants"
    />
  </PageLayout>
</template>
