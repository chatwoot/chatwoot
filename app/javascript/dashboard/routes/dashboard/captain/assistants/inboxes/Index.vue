<script setup>
import { computed, onBeforeMount, ref, nextTick } from 'vue';
import {
  useMapGetter,
  useStore,
  useStoreGetters,
} from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import BackButton from 'dashboard/components/widgets/BackButton.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CreateAssistantDialog from 'dashboard/components-next/captain/pageComponents/assistant/CreateAssistantDialog.vue';

const store = useStore();
const dialogType = ref('');
const route = useRoute();
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isFetchingAssistant = computed(() => uiFlags.value.fetchingList);

// const assistants = useMapGetter('captainAssistants/getCaptainAssistants');

const selectedAssistant = ref(null);
const deleteAssistantDialog = ref(null);
const { t } = useI18n();

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
  });
};

const handleCreateClose = () => {
  dialogType.value = '';
  selectedAssistant.value = null;
};

const getters = useStoreGetters();
const assistant = computed(() =>
  getters['captainAssistants/getCaptainAssistant'].value(
    route.params.assistantId
  )
);
onBeforeMount(() =>
  store.dispatch('captainAssistants/show', route.params.assistantId)
);
</script>

<template>
  <div
    v-if="isFetchingAssistant"
    class="flex items-center justify-center py-10 text-n-slate-11"
  >
    <Spinner />
  </div>
  <PageLayout
    v-else
    :button-label="$t('CAPTAIN.CONNECTED_INBOXES.ADD_NEW')"
    :show-pagination-footer="false"
    @click="handleCreate"
  >
    <template #headerTitle>
      <div class="flex flex-row items-center gap-4">
        <BackButton compact />
        <span class="flex items-center gap-1 text-lg">
          {{ assistant.name }}
          <span class="i-lucide-chevron-right text-xl text-n-slate-10" />
          {{ $t('CAPTAIN.CONNECTED_INBOXES.HEADER') }}
        </span>
      </div>
    </template>
    <!-- <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div> -->
    <!-- <div v-else-if="assistants.length" class="flex flex-col gap-4"> -->
    <!-- <AssistantCard
        v-for="assistant in assistants"
        :id="assistant.id"
        :key="assistant.id"
        :name="assistant.name"
        :description="assistant.description"
        :updated-at="assistant.updated_at || assistant.created_at"
        :created-at="assistant.created_at"
        @action="handleAction"
      /> -->
    <!-- </div> -->

    <div>{{ 'There are no connected inboxes' }}</div>

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
