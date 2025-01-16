<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import AssistantCard from 'dashboard/components-next/captain/assistant/AssistantCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CreateAssistantDialog from 'dashboard/components-next/captain/pageComponents/assistant/CreateAssistantDialog.vue';
import AssistantPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/AssistantPageEmptyState.vue';
import { useRouter } from 'vue-router';

const router = useRouter();

const store = useStore();
const dialogType = ref('');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const assistants = useMapGetter('captainAssistants/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedAssistant = ref(null);
const deleteAssistantDialog = ref(null);

const handleDelete = () => {
  deleteAssistantDialog.value.dialogRef.open();
};

const createAssistantDialog = ref(null);

const handleCreate = () => {
  dialogType.value = 'create';
  nextTick(() => createAssistantDialog.value.dialogRef.open());
};

const handleEdit = () => {
  dialogType.value = 'edit';
  nextTick(() => createAssistantDialog.value.dialogRef.open());
};

const handleViewConnectedInboxes = () => {
  router.push({
    name: 'captain_assistants_inboxes_index',
    params: { assistantId: selectedAssistant.value.id },
  });
};

const handleAction = ({ action, id }) => {
  selectedAssistant.value = assistants.value.find(
    assistant => id === assistant.id
  );
  nextTick(() => {
    if (action === 'delete') {
      handleDelete();
    }
    if (action === 'edit') {
      handleEdit();
    }
    if (action === 'viewConnectedInboxes') {
      handleViewConnectedInboxes();
    }
  });
};

const handleCreateClose = () => {
  dialogType.value = '';
  selectedAssistant.value = null;
};

onMounted(() => store.dispatch('captainAssistants/get'));
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.HEADER')"
    :button-label="$t('CAPTAIN.ASSISTANTS.ADD_NEW')"
    :show-pagination-footer="false"
    @click="handleCreate"
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

    <AssistantPageEmptyState v-else @click="handleCreate" />

    <DeleteDialog
      v-if="selectedAssistant"
      ref="deleteAssistantDialog"
      :entity="selectedAssistant"
      type="Assistants"
    />

    <CreateAssistantDialog
      v-if="dialogType"
      ref="createAssistantDialog"
      :type="dialogType"
      :selected-assistant="selectedAssistant"
      @close="handleCreateClose"
    />
  </PageLayout>
</template>
