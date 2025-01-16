<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import DocumentCard from 'dashboard/components-next/captain/assistant/DocumentCard.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import RelatedResponses from 'dashboard/components-next/captain/pageComponents/document/RelatedResponses.vue';
import CreateDocumentDialog from 'dashboard/components-next/captain/pageComponents/document/CreateDocumentDialog.vue';
import AssistantSelector from 'dashboard/components-next/captain/pageComponents/AssistantSelector.vue';
import DocumentPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/DocumentPageEmptyState.vue';

const store = useStore();

const uiFlags = useMapGetter('captainDocuments/getUIFlags');
const documents = useMapGetter('captainDocuments/getRecords');
const assistants = useMapGetter('captainAssistants/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);
const documentsMeta = useMapGetter('captainDocuments/getMeta');
const selectedAssistant = ref('all');

const selectedDocument = ref(null);
const deleteDocumentDialog = ref(null);

const handleDelete = () => {
  deleteDocumentDialog.value.dialogRef.open();
};

const showRelatedResponses = ref(false);
const showCreateDialog = ref(false);
const createDocumentDialog = ref(null);
const relationQuestionDialog = ref(null);

const shouldShowAssistantSelector = computed(() => {
  if (assistants.value.length === 0) return false;

  return !isFetching.value;
});

const handleShowRelatedDocument = () => {
  showRelatedResponses.value = true;
  nextTick(() => relationQuestionDialog.value.dialogRef.open());
};
const handleCreateDocument = () => {
  showCreateDialog.value = true;
  nextTick(() => createDocumentDialog.value.dialogRef.open());
};

const handleRelatedResponseClose = () => {
  showRelatedResponses.value = false;
};

const handleCreateDialogClose = () => {
  showCreateDialog.value = false;
};

const handleAction = ({ action, id }) => {
  selectedDocument.value = documents.value.find(
    captainDocument => id === captainDocument.id
  );

  nextTick(() => {
    if (action === 'delete') {
      handleDelete();
    } else if (action === 'viewRelatedQuestions') {
      handleShowRelatedDocument();
    }
  });
};

const fetchDocuments = (page = 1) => {
  const filterParams = { page };

  if (selectedAssistant.value !== 'all') {
    filterParams.assistantId = selectedAssistant.value;
  }
  store.dispatch('captainDocuments/get', filterParams);
};

const handleAssistantFilterChange = assistant => {
  selectedAssistant.value = assistant;
  fetchDocuments();
};

const onPageChange = page => fetchDocuments(page);

onMounted(() => {
  if (!assistants.value.length) {
    store.dispatch('captainAssistants/get');
  }
  fetchDocuments();
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.DOCUMENTS.HEADER')"
    :button-label="$t('CAPTAIN.DOCUMENTS.ADD_NEW')"
    :total-count="documentsMeta.totalCount"
    :current-page="documentsMeta.page"
    :show-pagination-footer="!isFetching && !!documents.length"
    @update:current-page="onPageChange"
    @click="handleCreateDocument"
  >
    <div v-if="shouldShowAssistantSelector" class="mb-4 -mt-3 flex gap-3">
      <AssistantSelector
        :assistant-id="selectedAssistant"
        @update="handleAssistantFilterChange"
      />
    </div>
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <div v-else-if="documents.length" class="flex flex-col gap-4">
      <DocumentCard
        v-for="doc in documents"
        :id="doc.id"
        :key="doc.id"
        :name="doc.name || doc.external_link"
        :external-link="doc.external_link"
        :assistant="doc.assistant"
        :created-at="doc.created_at"
        @action="handleAction"
      />
    </div>

    <DocumentPageEmptyState v-else @click="handleCreateDocument" />

    <RelatedResponses
      v-if="showRelatedResponses"
      ref="relationQuestionDialog"
      :captain-document="selectedDocument"
      @close="handleRelatedResponseClose"
    />
    <CreateDocumentDialog
      v-if="showCreateDialog"
      ref="createDocumentDialog"
      @close="handleCreateDialogClose"
    />
    <DeleteDialog
      v-if="selectedDocument"
      ref="deleteDocumentDialog"
      :entity="selectedDocument"
      type="Documents"
    />
  </PageLayout>
</template>
