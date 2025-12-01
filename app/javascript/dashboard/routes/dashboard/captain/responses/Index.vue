<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { debounce } from '@chatwoot/utils';
import { useAccount } from 'dashboard/composables/useAccount';

import Banner from 'dashboard/components-next/banner/Banner.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import BulkDeleteDialog from 'dashboard/components-next/captain/pageComponents/BulkDeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import ResponseCard from 'dashboard/components-next/captain/assistant/ResponseCard.vue';
import CreateResponseDialog from 'dashboard/components-next/captain/pageComponents/response/CreateResponseDialog.vue';
import ResponsePageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/ResponsePageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import LimitBanner from 'dashboard/components-next/captain/pageComponents/response/LimitBanner.vue';

const router = useRouter();
const route = useRoute();
const store = useStore();
const { isOnChatwootCloud } = useAccount();
const uiFlags = useMapGetter('captainResponses/getUIFlags');
const responseMeta = useMapGetter('captainResponses/getMeta');
const responses = useMapGetter('captainResponses/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedResponse = ref(null);
const deleteDialog = ref(null);
const bulkDeleteDialog = ref(null);

const dialogType = ref('');
const searchQuery = ref('');
const { t } = useI18n();

const createDialog = ref(null);

const selectedAssistantId = computed(() => Number(route.params.assistantId));

const pendingCount = useMapGetter('captainResponses/getPendingCount');

const handleDelete = () => {
  deleteDialog.value.dialogRef.open();
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
  });
};

const handleNavigationAction = ({ id, type }) => {
  if (type === 'Conversation') {
    router.push({
      name: 'inbox_conversation',
      params: { conversation_id: id },
    });
  }
};

const handleCreateClose = () => {
  dialogType.value = '';
  selectedResponse.value = null;
};

const updateURLWithFilters = (page, search) => {
  const query = {
    page: page || 1,
  };

  if (search) {
    query.search = search;
  }

  router.replace({ query });
};

const fetchResponses = (page = 1) => {
  const filterParams = { page, status: 'approved' };

  if (selectedAssistantId.value) {
    filterParams.assistantId = selectedAssistantId.value;
  }
  if (searchQuery.value) {
    filterParams.search = searchQuery.value;
  }

  // Update URL with current filters
  updateURLWithFilters(page, searchQuery.value);

  store.dispatch('captainResponses/get', filterParams);
};

// Bulk action
const bulkSelectedIds = ref(new Set());
const hoveredCard = ref(null);

const buildSelectedCountLabel = computed(() => {
  const count = responses.value?.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.RESPONSES.UNSELECT_ALL', { count })
    : t('CAPTAIN.RESPONSES.SELECT_ALL', { count });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.RESPONSES.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const handleCardHover = (isHovered, id) => {
  hoveredCard.value = isHovered ? id : null;
};

const handleCardSelect = id => {
  const selected = new Set(bulkSelectedIds.value);
  selected[selected.has(id) ? 'delete' : 'add'](id);
  bulkSelectedIds.value = selected;
};

const fetchResponseAfterBulkAction = () => {
  const hasNoResponsesLeft = responses.value?.length === 0;
  const currentPage = responseMeta.value?.page;

  if (hasNoResponsesLeft) {
    // Page is now empty after bulk action.
    // Fetch the previous page if not already on the first page.
    const pageToFetch = currentPage > 1 ? currentPage - 1 : currentPage;
    fetchResponses(pageToFetch);
  } else {
    // Page still has responses left, re-fetch the same page.
    fetchResponses(currentPage);
  }

  // Clear selection
  bulkSelectedIds.value = new Set();
};

const onPageChange = page => {
  const hadSelection = bulkSelectedIds.value.size > 0;

  fetchResponses(page);

  if (hadSelection) {
    bulkSelectedIds.value = new Set();
  }
};

const onDeleteSuccess = () => {
  if (responses.value?.length === 0 && responseMeta.value?.page > 1) {
    onPageChange(responseMeta.value.page - 1);
  }
};

const onBulkDeleteSuccess = () => {
  fetchResponseAfterBulkAction();
};

const debouncedSearch = debounce(async () => {
  fetchResponses(1);
}, 500);

const initializeFromURL = () => {
  if (route.query.search) {
    searchQuery.value = route.query.search;
  }
  const pageFromURL = parseInt(route.query.page, 10) || 1;
  fetchResponses(pageFromURL);
};

const navigateToPendingFAQs = () => {
  router.push({ name: 'captain_assistants_responses_pending' });
};

onMounted(() => {
  initializeFromURL();
  store.dispatch(
    'captainResponses/fetchPendingCount',
    selectedAssistantId.value
  );
});
</script>

<template>
  <PageLayout
    :total-count="responseMeta.totalCount"
    :current-page="responseMeta.page"
    :button-policy="['administrator']"
    :header-title="$t('CAPTAIN.RESPONSES.HEADER')"
    :button-label="$t('CAPTAIN.RESPONSES.ADD_NEW')"
    :is-fetching="isFetching"
    :is-empty="!responses.length"
    :show-pagination-footer="!isFetching && !!responses.length"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    @update:current-page="onPageChange"
    @click="handleCreate"
  >
    <template #knowMore>
      <FeatureSpotlightPopover
        :button-label="$t('CAPTAIN.HEADER_KNOW_MORE')"
        :title="$t('CAPTAIN.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
        :note="$t('CAPTAIN.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
        :hide-actions="!isOnChatwootCloud"
        fallback-thumbnail="/assets/images/dashboard/captain/faqs-popover-light.svg"
        fallback-thumbnail-dark="/assets/images/dashboard/captain/faqs-popover-dark.svg"
        learn-more-url="https://chwt.app/captain-faq"
      />
    </template>

    <template #search>
      <div
        v-if="bulkSelectedIds.size === 0"
        class="flex gap-3 justify-between w-full items-center"
      >
        <Input
          v-model="searchQuery"
          :placeholder="$t('CAPTAIN.RESPONSES.SEARCH_PLACEHOLDER')"
          class="w-64"
          size="sm"
          type="search"
          autofocus
          @input="debouncedSearch"
        />
      </div>
    </template>

    <template #subHeader>
      <BulkSelectBar
        v-model="bulkSelectedIds"
        :all-items="responses"
        :select-all-label="buildSelectedCountLabel"
        :selected-count-label="selectedCountLabel"
        :delete-label="$t('CAPTAIN.RESPONSES.BULK_DELETE_BUTTON')"
        class="w-fit"
        :class="{
          'mb-2': bulkSelectedIds.size > 0,
        }"
        @bulk-delete="bulkDeleteDialog.dialogRef.open()"
      />
    </template>

    <template #emptyState>
      <ResponsePageEmptyState @click="handleCreate" />
    </template>

    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #body>
      <LimitBanner class="mb-5" />
      <Banner
        v-if="pendingCount > 0"
        color="blue"
        class="mb-4 -mt-3"
        :action-label="$t('CAPTAIN.RESPONSES.PENDING_BANNER.ACTION')"
        @action="navigateToPendingFAQs"
      >
        {{ $t('CAPTAIN.RESPONSES.PENDING_BANNER.TITLE') }}
      </Banner>

      <div class="flex flex-col gap-4">
        <ResponseCard
          v-for="response in responses"
          :id="response.id"
          :key="response.id"
          :question="response.question"
          :answer="response.answer"
          :assistant="response.assistant"
          :documentable="response.documentable"
          :status="response.status"
          :created-at="response.created_at"
          :updated-at="response.updated_at"
          :is-selected="bulkSelectedIds.has(response.id)"
          :selectable="hoveredCard === response.id || bulkSelectedIds.size > 0"
          :show-menu="!bulkSelectedIds.has(response.id)"
          :show-actions="false"
          @action="handleAction"
          @navigate="handleNavigationAction"
          @select="handleCardSelect"
          @hover="isHovered => handleCardHover(isHovered, response.id)"
        />
      </div>
    </template>

    <DeleteDialog
      v-if="selectedResponse"
      ref="deleteDialog"
      :entity="selectedResponse"
      type="Responses"
      @delete-success="onDeleteSuccess"
    />

    <BulkDeleteDialog
      v-if="bulkSelectedIds"
      ref="bulkDeleteDialog"
      :bulk-ids="bulkSelectedIds"
      type="Responses"
      @delete-success="onBulkDeleteSuccess"
    />

    <CreateResponseDialog
      v-if="dialogType"
      ref="createDialog"
      :type="dialogType"
      :selected-response="selectedResponse"
      @close="handleCreateClose"
    />
  </PageLayout>
</template>
