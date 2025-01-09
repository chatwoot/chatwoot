<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import DocumentCard from 'dashboard/components-next/captain/assistant/DocumentCard.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import RelatedResponses from 'dashboard/components-next/captain/pageComponents/document/RelatedResponses.vue';
const store = useStore();

const uiFlags = useMapGetter('captainDocuments/getUIFlags');
const documents = useMapGetter('captainDocuments/getCaptainDocuments');
const isFetching = computed(() => uiFlags.value.fetchingList);
const documentsMeta = useMapGetter('captainDocuments/getMeta');

const selectedDocument = ref(null);
const deleteDialog = ref(null);

const handleDelete = () => {
  deleteDialog.value.dialogRef.open();
};

const showRelatedResponses = ref(false);
const relationQuestionDialog = ref(null);

const handleShowRelatedDocument = () => {
  showRelatedResponses.value = true;
  nextTick(() => relationQuestionDialog.value.dialogRef.open());
};

const handleRelatedResponseClose = () => {
  showRelatedResponses.value = false;
};

const handleAction = ({ action, id }) => {
  selectedDocument.value = documents.value.find(
    captainDocument => id === captainDocument.id
  );

  if (action === 'delete') {
    handleDelete();
  } else if (action === 'viewRelatedQuestions') {
    handleShowRelatedDocument();
  }
};

const fetchDocuments = (page = 1) => {
  store.dispatch('captainDocuments/get', { page });
};

const onPageChange = page => fetchDocuments(page);

onMounted(() => fetchDocuments());
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.DOCUMENTS.HEADER')"
    :button-label="$t('CAPTAIN.DOCUMENTS.ADD_NEW')"
    :total-count="documentsMeta.totalCount"
    :current-page="documentsMeta.page"
    :show-pagination-footer="!isFetching && !!documents.length"
    @update:current-page="onPageChange"
  >
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
        :name="doc.name"
        :external-link="doc.external_link"
        :assistant="doc.assistant"
        :created-at="doc.created_at"
        @action="handleAction"
      />
    </div>

    <div v-else>{{ 'No documents found' }}</div>
    <RelatedResponses
      v-if="showRelatedResponses"
      ref="relationQuestionDialog"
      :captain-document="selectedDocument"
      @close="handleRelatedResponseClose"
    />
    <DeleteDialog
      v-if="selectedDocument"
      ref="deleteDialog"
      :entity="selectedDocument"
      type="Documents"
    />
  </PageLayout>
</template>
