<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import PageLayout from 'dashboard/components-next/ai_agent/PageLayout.vue';
import DocumentCard from 'dashboard/components-next/ai_agent/topic/DocumentCard.vue';
import DeleteDialog from 'dashboard/components-next/ai_agent/pageComponents/DeleteDialog.vue';
import CreateDocumentDialog from 'dashboard/components-next/ai_agent/pageComponents/document/CreateDocumentDialog.vue';
import RelatedResponses from 'dashboard/components-next/ai_agent/pageComponents/document/RelatedResponses.vue';
import DocumentPageEmptyState from 'dashboard/components-next/ai_agent/pageComponents/emptyStates/DocumentPageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import AIAgentPaywall from 'dashboard/components-next/ai_agent/pageComponents/Paywall.vue';
import LimitBanner from 'dashboard/components-next/ai_agent/pageComponents/document/LimitBanner.vue';
import TopicSelector from 'dashboard/components-next/ai_agent/pageComponents/TopicSelector.vue';

const store = useStore();

const uiFlags = ref({ fetchingList: true }); // Mock UI flags for demo
const documents = ref([]);
const topics = ref([]);
const isFetching = computed(() => uiFlags.value.fetchingList);
const documentsMeta = ref({ totalCount: 0, page: 1 });
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
  selectedDocument.value = documents.value.find(document => id === document.id);

  nextTick(() => {
    if (action === 'delete') {
      handleDelete();
    } else if (action === 'viewRelatedQuestions') {
      handleShowRelatedDocument();
    }
  });
};

const fetchDocuments = (page = 1) => {
  // In a real implementation, we would fetch documents from the API
  setTimeout(() => {
    documents.value = [
      {
        id: 1,
        name: 'Product Manual',
        external_link: 'https://example.com/product-manual.pdf',
        content_type: 'application/pdf',
        size: 1024 * 1024, // 1MB
        created_at: Date.now(),
        topic: { name: 'Product Knowledge' },
      },
      {
        id: 2,
        name: 'Pricing Information',
        external_link: 'https://example.com/pricing-info.txt',
        content_type: 'text/plain',
        size: 512 * 1024, // 512KB
        created_at: Date.now(),
        topic: { name: 'Product Knowledge' },
      },
    ];
    uiFlags.value.fetchingList = false;
  }, 1000);
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
  // In a real implementation, we would fetch topics from the API
  topics.value = [
    { id: 1, name: 'Product Knowledge' },
    { id: 2, name: 'Support Policies' },
  ];
  fetchDocuments();
});
</script>

<template>
  <PageLayout
    :header-title="$t('AI_AGENT.DOCUMENTS.HEADER')"
    :button-label="$t('AI_AGENT.DOCUMENTS.ADD')"
    :button-policy="['administrator']"
    :total-count="documentsMeta.totalCount"
    :current-page="documentsMeta.page"
    :show-pagination-footer="!isFetching && !!documents.length"
    :is-fetching="isFetching"
    :is-empty="!documents.length"
    :feature-flag="FEATURE_FLAGS.AI_AGENT"
    @update:current-page="onPageChange"
    @click="handleCreateDocument"
  >
    <template #knowMore>
      <FeatureSpotlightPopover
        :button-label="$t('AI_AGENT.HEADER_KNOW_MORE')"
        :title="$t('AI_AGENT.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
        :note="$t('AI_AGENT.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
        fallback-thumbnail="/assets/images/dashboard/ai_agent/document-popover-light.svg"
        fallback-thumbnail-dark="/assets/images/dashboard/ai_agent/document-popover-dark.svg"
        learn-more-url="https://chwt.app/ai-agent-document"
      />
    </template>

    <template #emptyState>
      <DocumentPageEmptyState @click="handleCreateDocument" />
    </template>

    <template #paywall>
      <AIAgentPaywall />
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
      :document="selectedDocument"
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

<style lang="scss" scoped>
.column-content {
  height: 100%;
  padding: var(--space-small);
  overflow-y: auto;
}

.search-container {
  margin-bottom: var(--space-normal);
}

.empty-state-container {
  display: flex;
  height: 100%;
  align-items: center;
  justify-content: center;
}

.documents-container {
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
}

.document-card {
  display: flex;
  align-items: center;
  padding: var(--space-normal);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  background-color: var(--white);
  transition: all 0.3s ease;

  &:hover {
    box-shadow: var(--shadow-small);
  }
}

.document-icon {
  margin-right: var(--space-normal);
  color: var(--color-woot);
}

.document-details {
  flex-grow: 1;
}

.document-title {
  font-weight: var(--font-weight-medium);
  margin-bottom: var(--space-smaller);
}

.document-meta {
  display: flex;
  gap: var(--space-normal);
  font-size: var(--font-size-small);
  color: var(--color-body);
}

.document-actions {
  display: flex;
  gap: var(--space-smaller);
}
</style>
