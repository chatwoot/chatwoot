<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import PageLayout from 'dashboard/components-next/ai_agent/PageLayout.vue';
import ResponseCard from 'dashboard/components-next/ai_agent/topic/ResponseCard.vue';
import DeleteDialog from 'dashboard/components-next/ai_agent/pageComponents/DeleteDialog.vue';
import CreateResponseDialog from 'dashboard/components-next/ai_agent/pageComponents/response/CreateResponseDialog.vue';
import ResponsePageEmptyState from 'dashboard/components-next/ai_agent/pageComponents/emptyStates/ResponsePageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import AIAgentPaywall from 'dashboard/components-next/ai_agent/pageComponents/Paywall.vue';
import LimitBanner from 'dashboard/components-next/ai_agent/pageComponents/response/LimitBanner.vue';
import TopicSelector from 'dashboard/components-next/ai_agent/pageComponents/TopicSelector.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const uiFlags = ref({ fetchingList: true }); // Mock UI flags for demo
const topics = ref([]);
const responseMeta = ref({ totalCount: 0, page: 1 });
const responses = ref([]);
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedResponse = ref(null);
const deleteDialog = ref(null);
const selectedStatus = ref('all');
const selectedTopic = ref('all');
const dialogType = ref('');

const createDialog = ref(null);

const handleDelete = () => {
  deleteDialog.value.dialogRef.open();
};

const handleAccept = async () => {
  try {
    // In a real implementation, we would call the API to approve the response
    // For now, just update the status in our local data
    const response = responses.value.find(
      r => r.id === selectedResponse.value.id
    );
    if (response) {
      response.status = 'approved';
    }
  } catch (error) {
    // Handle error
  } finally {
    selectedResponse.value = null;
  }
};

const handleCreate = () => {
  dialogType.value = 'create';
  nextTick(() => createDialog.value.dialogRef.open());
};

const handleEdit = () => {
  dialogType.value = 'edit';
  nextTick(() => createDialog.value.dialogRef.open());
};

const handleAction = ({ action, id }) => {
  selectedResponse.value = responses.value.find(response => id === response.id);
  nextTick(() => {
    if (action === 'delete') {
      handleDelete();
    }
    if (action === 'edit') {
      handleEdit();
    }
    if (action === 'approve') {
      handleAccept();
    }
  });
};

const handleCreateClose = () => {
  dialogType.value = '';
  selectedResponse.value = null;
};

const fetchResponses = (page = 1) => {
  // In a real implementation, we would fetch responses from the API
  setTimeout(() => {
    responses.value = [
      {
        id: 1,
        question: 'Product Return Policy',
        answer:
          'Our product return policy allows returns within 30 days of purchase...',
        status: 'approved',
        updated_at: Date.now(),
        created_at: Date.now(),
        topic: { name: 'Product Knowledge' },
      },
      {
        id: 2,
        question: 'Shipping Information',
        answer: 'We offer free shipping on orders over $50...',
        status: 'approved',
        updated_at: Date.now(),
        created_at: Date.now(),
        topic: { name: 'Product Knowledge' },
      },
    ];
    uiFlags.value.fetchingList = false;
  }, 1000);
};

const handleTopicFilterChange = topic => {
  selectedTopic.value = topic;
  fetchResponses();
};

const onPageChange = page => fetchResponses(page);

const onDeleteSuccess = () => {
  if (responses.value?.length === 0 && responseMeta.value?.page > 1) {
    onPageChange(responseMeta.value.page - 1);
  }
};

onMounted(() => {
  // In a real implementation, we would fetch topics from the API
  topics.value = [
    { id: 1, name: 'Product Knowledge' },
    { id: 2, name: 'Support Policies' },
  ];
  fetchResponses();
});
</script>

<template>
  <PageLayout
    :header-title="$t('AI_AGENT.RESPONSES.HEADER')"
    :button-label="$t('AI_AGENT.RESPONSES.ADD')"
    :button-policy="['administrator']"
    :total-count="responseMeta.totalCount"
    :current-page="responseMeta.page"
    :show-pagination-footer="!isFetching && !!responses.length"
    :is-fetching="isFetching"
    :is-empty="!responses.length"
    :feature-flag="FEATURE_FLAGS.AI_AGENT"
    @update:current-page="onPageChange"
    @click="handleCreate"
  >
    <template #knowMore>
      <FeatureSpotlightPopover
        :button-label="$t('AI_AGENT.HEADER_KNOW_MORE')"
        :title="$t('AI_AGENT.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
        :note="$t('AI_AGENT.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
        fallback-thumbnail="/assets/images/dashboard/ai_agent/response-popover-light.svg"
        fallback-thumbnail-dark="/assets/images/dashboard/ai_agent/response-popover-dark.svg"
        learn-more-url="https://chwt.app/ai-agent-responses"
      />
    </template>

    <template #emptyState>
      <ResponsePageEmptyState @click="handleCreate" />
    </template>

    <template #paywall>
      <AIAgentPaywall />
    </template>

    <template #controls>
      <div class="mb-4 -mt-3 flex gap-3">
        <TopicSelector
          :topic-id="selectedTopic"
          @update="handleTopicFilterChange"
        />
      </div>
    </template>

    <template #body>
      <LimitBanner class="mb-5" />

      <div class="flex flex-col gap-4">
        <ResponseCard
          v-for="response in responses"
          :id="response.id"
          :key="response.id"
          :question="response.question"
          :answer="response.answer"
          :status="response.status"
          :topic="response.topic"
          :updated-at="response.updated_at || response.created_at"
          :created-at="response.created_at"
          @action="handleAction"
        />
      </div>
    </template>

    <CreateResponseDialog
      v-if="dialogType"
      ref="createDialog"
      :type="dialogType"
      :selected-response="selectedResponse"
      @close="handleCreateClose"
    />
    <DeleteDialog
      v-if="selectedResponse"
      ref="deleteDialog"
      :entity="selectedResponse"
      type="Responses"
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

.responses-container {
  display: flex;
  flex-direction: column;
  gap: var(--space-small);
}

.response-card {
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

.response-details {
  flex-grow: 1;
}

.response-title {
  font-weight: var(--font-weight-medium);
  margin-bottom: var(--space-smaller);
}

.response-content {
  font-size: var(--font-size-small);
  color: var(--color-body);
  margin-bottom: var(--space-smaller);
}

.response-meta {
  font-size: var(--font-size-mini);
  color: var(--color-light-gray);
}

.response-actions {
  display: flex;
  gap: var(--space-smaller);
}
</style>
