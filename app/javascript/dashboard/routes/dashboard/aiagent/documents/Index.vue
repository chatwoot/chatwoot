<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import DeleteDialog from 'dashboard/components-next/aiagent/pageComponents/DeleteDialog.vue';
import DocumentCard from 'dashboard/components-next/aiagent/topic/DocumentCard.vue';
import PageLayout from 'dashboard/components-next/aiagent/PageLayout.vue';
import AiagentPaywall from 'dashboard/components-next/aiagent/pageComponents/Paywall.vue';
import RelatedResponses from 'dashboard/components-next/aiagent/pageComponents/document/RelatedResponses.vue';
import CreateDocumentDialog from 'dashboard/components-next/aiagent/pageComponents/document/CreateDocumentDialog.vue';
import TopicSelector from 'dashboard/components-next/aiagent/pageComponents/TopicSelector.vue';
import DocumentPageEmptyState from 'dashboard/components-next/aiagent/pageComponents/emptyStates/DocumentPageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import LimitBanner from 'dashboard/components-next/aiagent/pageComponents/document/LimitBanner.vue';

const store = useStore();

const uiFlags = useMapGetter('aiagentDocuments/getUIFlags');
const documents = useMapGetter('aiagentDocuments/getRecords');
const topics = useMapGetter('aiagentTopics/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);
const documentsMeta = useMapGetter('aiagentDocuments/getMeta');
const selectedTopic = ref('all');

const selectedDocument = ref(null);
const deleteDocumentDialog = ref(null);

const handleDelete = () => {
  deleteDocumentDialog.value.dialogRef.open();
};

const showRelatedResponses = ref(false);
const showCreateDialog = ref(false);
const createDocumentDialog = ref(null);
const relationQuestionDialog = ref(null);

const shouldShowTopicSelector = computed(() => {
  if (topics.value.length === 0) return false;

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
    aiagentDocument => id === aiagentDocument.id
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

  if (selectedTopic.value !== 'all') {
    filterParams.topicId = selectedTopic.value;
  }
  store.dispatch('aiagentDocuments/get', filterParams);
};

const handleTopicFilterChange = topic => {
  selectedTopic.value = topic;
  fetchDocuments();
};

const onPageChange = page => fetchDocuments(page);

const onDeleteSuccess = () => {
  if (documents.value?.length === 0 && documentsMeta.value?.page > 1) {
    onPageChange(documentsMeta.value.page - 1);
  }
};

onMounted(() => {
  if (!topics.value.length) {
    store.dispatch('aiagentTopics/get');
  }
  fetchDocuments();
});
</script>

<template>
  <PageLayout
    :header-title="$t('AIAGENT.DOCUMENTS.HEADER')"
    :button-label="$t('AIAGENT.DOCUMENTS.ADD_NEW')"
    :button-policy="['administrator']"
    :total-count="documentsMeta.totalCount"
    :current-page="documentsMeta.page"
    :show-pagination-footer="!isFetching && !!documents.length"
    :is-fetching="isFetching"
    :is-empty="!documents.length"
    :feature-flag="FEATURE_FLAGS.AIAGENT"
    @update:current-page="onPageChange"
    @click="handleCreateDocument"
  >
    <template #knowMore>
      <FeatureSpotlightPopover
        :button-label="$t('AIAGENT.HEADER_KNOW_MORE')"
        :title="$t('AIAGENT.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
        :note="$t('AIAGENT.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
        fallback-thumbnail="/assets/images/dashboard/aiagent/document-popover-light.svg"
        fallback-thumbnail-dark="/assets/images/dashboard/aiagent/document-popover-dark.svg"
        learn-more-url="https://chwt.app/aiagent-document"
      />
    </template>

    <template #emptyState>
      <DocumentPageEmptyState @click="handleCreateDocument" />
    </template>

    <template #paywall>
      <AiagentPaywall />
    </template>

    <template #controls>
      <div v-if="shouldShowTopicSelector" class="mb-4 -mt-3 flex gap-3">
        <TopicSelector
          :topic-id="selectedTopic"
          @update="handleTopicFilterChange"
        />
      </div>
    </template>

    <template #body>
      <LimitBanner class="mb-5" />

      <div class="flex flex-col gap-4">
        <DocumentCard
          v-for="doc in documents"
          :id="doc.id"
          :key="doc.id"
          :name="doc.name || doc.external_link"
          :external-link="doc.external_link"
          :topic="doc.topic"
          :created-at="doc.created_at"
          @action="handleAction"
        />
      </div>
    </template>

    <RelatedResponses
      v-if="showRelatedResponses"
      ref="relationQuestionDialog"
      :aiagent-document="selectedDocument"
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
      @delete-success="onDeleteSuccess"
    />
  </PageLayout>
</template>
