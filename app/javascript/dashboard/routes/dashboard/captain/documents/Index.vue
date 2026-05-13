<script setup>
import { computed, onUnmounted, ref, nextTick, watch } from 'vue';
import { useTimeoutPoll } from '@vueuse/core';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { debounce } from '@chatwoot/utils';

import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import DocumentCard from 'dashboard/components-next/captain/assistant/DocumentCard.vue';
import DocumentFilter from 'dashboard/components-next/captain/assistant/DocumentFilter.vue';
import DocumentBulkActions from 'dashboard/components-next/captain/assistant/DocumentBulkActions.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Policy from 'dashboard/components/policy.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import RelatedResponses from 'dashboard/components-next/captain/pageComponents/document/RelatedResponses.vue';
import CreateDocumentDialog from 'dashboard/components-next/captain/pageComponents/document/CreateDocumentDialog.vue';
import DocumentPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/DocumentPageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import LimitBanner from 'dashboard/components-next/captain/pageComponents/document/LimitBanner.vue';
import CaptainDocumentAPI from 'dashboard/api/captain/document';
import { useI18n } from 'vue-i18n';

const route = useRoute();
const store = useStore();
const { t } = useI18n();
const { checkPermissions } = usePolicy();

const SYNC_POLL_INTERVAL_MS = 5000;
const SYNC_POLL_MAX_DURATION_MS = 15 * 60 * 1000;

const { isOnChatwootCloud } = useAccount();
const uiFlags = useMapGetter('captainDocuments/getUIFlags');
const documents = useMapGetter('captainDocuments/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);
const documentsMeta = useMapGetter('captainDocuments/getMeta');

const selectedAssistantId = computed(() => Number(route.params.assistantId));
const canManageDocuments = computed(() => checkPermissions(['administrator']));

const selectedDocument = ref(null);
const deleteDocumentDialog = ref(null);
const bulkSelectedIds = ref(new Set());
const hoveredCard = ref(null);

const handleDelete = () => {
  deleteDocumentDialog.value.dialogRef.open();
};

const showRelatedResponses = ref(false);
const showCreateDialog = ref(false);
const createDocumentDialog = ref(null);
const relationQuestionDialog = ref(null);

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

const documentFilter = ref(null);
const syncIntervalHours = ref(null);
const searchQuery = ref('');

const currentAssistantId = () =>
  Number.isFinite(selectedAssistantId.value) ? selectedAssistantId.value : null;

const buildDocumentFilterParams = (page = 1) => {
  const filterParams = documentFilter.value?.buildParams(page) ?? {
    page,
    sort: 'recently_updated',
  };
  const assistantId = currentAssistantId();
  if (assistantId) filterParams.assistantId = assistantId;
  const trimmedQuery = searchQuery.value.trim();
  if (trimmedQuery) filterParams.searchKey = trimmedQuery;
  return filterParams;
};

let documentsRequestId = 0;
let fetchingListRequestId = null;

const isCurrentDocumentRequest = (requestId, filterParams) =>
  requestId === documentsRequestId &&
  (filterParams.assistantId || null) === currentAssistantId();

const pruneSelectionToDocuments = nextDocuments => {
  if (!bulkSelectedIds.value.size) return;

  const visibleDocumentIds = new Set(nextDocuments.map(doc => doc.id));
  const selectedIds = new Set(
    [...bulkSelectedIds.value].filter(id => visibleDocumentIds.has(id))
  );

  if (selectedIds.size !== bulkSelectedIds.value.size) {
    bulkSelectedIds.value = selectedIds;
  }
};

const fetchDocuments = async (page = 1, { showLoader = true } = {}) => {
  documentsRequestId += 1;
  const requestId = documentsRequestId;
  const filterParams = buildDocumentFilterParams(page);

  if (showLoader) {
    fetchingListRequestId = requestId;
    store.dispatch('captainDocuments/setFetchingList', true);
  }

  try {
    const response = await CaptainDocumentAPI.get(filterParams);

    if (!isCurrentDocumentRequest(requestId, filterParams)) {
      return [];
    }

    const { payload, meta } = response.data;
    store.dispatch('captainDocuments/setRecords', { records: payload, meta });
    pruneSelectionToDocuments(payload);
    syncIntervalHours.value = Number(meta?.sync_interval_hours) || null;
    return payload;
  } catch (error) {
    if (isCurrentDocumentRequest(requestId, filterParams)) {
      throw error;
    }
    return [];
  } finally {
    if (showLoader && fetchingListRequestId === requestId) {
      fetchingListRequestId = null;
      store.dispatch('captainDocuments/setFetchingList', false);
    }
  }
};

const refreshDocumentsPage = (
  page = documentsMeta.value?.page || 1,
  { showLoader = false } = {}
) => {
  return fetchDocuments(page, { showLoader }).catch(() => {});
};

const onFiltersChanged = () => {
  bulkSelectedIds.value = new Set();
  fetchDocuments(1);
};

const debouncedSearch = debounce(() => {
  bulkSelectedIds.value = new Set();
  fetchDocuments(1);
}, 300);

const syncPollStartedAt = ref(null);

const hasDocumentsSyncing = computed(() =>
  (documents.value || []).some(doc => doc.sync_in_progress)
);

const hasSyncingDocuments = computed(() => hasDocumentsSyncing.value);

const isWithinSyncPollWindow = () =>
  syncPollStartedAt.value &&
  Date.now() - syncPollStartedAt.value < SYNC_POLL_MAX_DURATION_MS;

const shouldContinueSyncPolling = () =>
  hasSyncingDocuments.value && isWithinSyncPollWindow();

let syncPollingControls;

function stopSyncPolling() {
  syncPollingControls.pause();
  syncPollStartedAt.value = null;
}

async function pollSyncDocuments() {
  try {
    await refreshDocumentsPage();
  } catch (error) {
    // Keep the existing polling decision based on the last known sync state.
  }

  if (!shouldContinueSyncPolling()) {
    stopSyncPolling();
  }
}

function scheduleSyncPoll({ extendWindow = false } = {}) {
  if (extendWindow || !syncPollStartedAt.value) {
    syncPollStartedAt.value = Date.now();
  }

  if (syncPollingControls.isActive.value) return;
  syncPollingControls.resume();
}

syncPollingControls = useTimeoutPoll(pollSyncDocuments, SYNC_POLL_INTERVAL_MS, {
  immediate: false,
});

watch(hasSyncingDocuments, isSyncing => {
  if (isSyncing) {
    scheduleSyncPoll();
  }
});

const handleSync = async id => {
  try {
    await store.dispatch('captainDocuments/sync', id);
    useAlert(t('CAPTAIN.DOCUMENTS.SYNC.QUEUED_MESSAGE'));
    scheduleSyncPoll({ extendWindow: true });
  } catch (error) {
    useAlert(t('CAPTAIN.DOCUMENTS.SYNC.ERROR_MESSAGE'));
  }
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
    } else if (action === 'sync') {
      handleSync(id);
    }
  });
};

const onPageChange = page => {
  const hadSelection = bulkSelectedIds.value.size > 0;
  fetchDocuments(page);

  if (hadSelection) {
    bulkSelectedIds.value = new Set();
  }
};

const onDeleteSuccess = () => {
  if (documents.value?.length === 0 && documentsMeta.value?.page > 1) {
    onPageChange(documentsMeta.value.page - 1);
  } else {
    refreshDocumentsPage();
  }
};

const shouldShowSelectionControl = docId =>
  canManageDocuments.value &&
  (hoveredCard.value === docId || bulkSelectedIds.value.size > 0);

const handleCardHover = (isHovered, id) => {
  hoveredCard.value = isHovered ? id : null;
};

const handleCardSelect = id => {
  if (!canManageDocuments.value) return;
  const selected = new Set(bulkSelectedIds.value);
  selected[selected.has(id) ? 'delete' : 'add'](id);
  bulkSelectedIds.value = selected;
};

const fetchDocumentsAfterBulkAction = () => {
  const hasNoDocumentsLeft = documents.value?.length === 0;
  const currentPage = documentsMeta.value?.page;

  if (hasNoDocumentsLeft) {
    const pageToFetch = currentPage > 1 ? currentPage - 1 : currentPage;
    fetchDocuments(pageToFetch);
  } else {
    fetchDocuments(currentPage);
  }

  bulkSelectedIds.value = new Set();
};

const onCreateSuccess = () => {
  refreshDocumentsPage(1);
};

const hasActiveDocumentFilters = computed(
  () =>
    (documentFilter.value?.hasActiveFilters ?? false) ||
    Boolean(searchQuery.value.trim())
);

watch(
  selectedAssistantId,
  async () => {
    documentFilter.value?.reset();
    searchQuery.value = '';
    bulkSelectedIds.value = new Set();
    syncIntervalHours.value = null;
    stopSyncPolling();
    await fetchDocuments(1);
    if (hasSyncingDocuments.value) scheduleSyncPoll();
  },
  { immediate: true }
);

onUnmounted(() => {
  stopSyncPolling();
  documentsRequestId += 1;
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.DOCUMENTS.HEADER')"
    :button-label="$t('CAPTAIN.DOCUMENTS.ADD_NEW')"
    :button-policy="['administrator']"
    :total-count="documentsMeta.totalCount"
    :current-page="documentsMeta.page"
    :show-pagination-footer="!isFetching && !!documents.length"
    :is-fetching="isFetching"
    :is-empty="!documents.length && !hasActiveDocumentFilters"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    @update:current-page="onPageChange"
    @click="handleCreateDocument"
  >
    <template #search>
      <div
        v-if="bulkSelectedIds.size === 0"
        class="flex gap-3 justify-between w-full items-center"
      >
        <Input
          v-model="searchQuery"
          :placeholder="$t('CAPTAIN.DOCUMENTS.FILTERS.SEARCH_PLACEHOLDER')"
          class="max-w-64 min-w-0 w-full"
          size="sm"
          type="search"
          @input="debouncedSearch"
        />
      </div>
    </template>

    <template #subHeader>
      <Policy :permissions="['administrator']">
        <DocumentBulkActions
          v-model:selected-ids="bulkSelectedIds"
          :documents="documents"
          @bulk-sync-queued="scheduleSyncPoll({ extendWindow: true })"
          @bulk-delete-succeeded="fetchDocumentsAfterBulkAction"
        />
      </Policy>
      <DocumentFilter
        v-show="!bulkSelectedIds.size"
        ref="documentFilter"
        class="mb-2"
        @change="onFiltersChanged"
      />
    </template>
    <template #knowMore>
      <FeatureSpotlightPopover
        :button-label="$t('CAPTAIN.HEADER_KNOW_MORE')"
        :title="$t('CAPTAIN.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
        :note="$t('CAPTAIN.DOCUMENTS.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
        :hide-actions="!isOnChatwootCloud"
        fallback-thumbnail="/assets/images/dashboard/captain/document-popover-light.svg"
        fallback-thumbnail-dark="/assets/images/dashboard/captain/document-popover-dark.svg"
        learn-more-url="https://chwt.app/captain-document"
      />
    </template>

    <template #emptyState>
      <DocumentPageEmptyState @click="handleCreateDocument" />
    </template>

    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #body>
      <LimitBanner class="mb-5" />

      <div
        v-if="!documents.length && hasActiveDocumentFilters"
        class="flex flex-col items-center justify-center min-h-80 gap-2 text-center"
      >
        <span class="text-base font-medium text-n-slate-12">
          {{ $t('CAPTAIN.DOCUMENTS.EMPTY_STATE.FILTERED_TITLE') }}
        </span>
        <span class="max-w-md text-sm text-n-slate-11">
          {{ $t('CAPTAIN.DOCUMENTS.EMPTY_STATE.FILTERED_SUBTITLE') }}
        </span>
      </div>

      <div v-else class="flex flex-col gap-4">
        <DocumentCard
          v-for="doc in documents"
          :id="doc.id"
          :key="doc.id"
          :name="doc.name || doc.external_link"
          :external-link="doc.external_link"
          :pdf-document="doc.pdf_document"
          :assistant="doc.assistant"
          :created-at="doc.created_at"
          :status="doc.status"
          :sync-status="doc.sync_status"
          :last-synced-at="doc.last_synced_at"
          :last-sync-error-code="doc.last_sync_error_code"
          :sync-in-progress="doc.sync_in_progress"
          :sync-stale-after-hours="syncIntervalHours"
          :is-selected="canManageDocuments && bulkSelectedIds.has(doc.id)"
          :selectable="canManageDocuments"
          :show-selection-control="shouldShowSelectionControl(doc.id)"
          :show-menu="!bulkSelectedIds.has(doc.id)"
          @action="handleAction"
          @select="handleCardSelect"
          @hover="isHovered => handleCardHover(isHovered, doc.id)"
        />
      </div>
    </template>

    <RelatedResponses
      v-if="showRelatedResponses"
      ref="relationQuestionDialog"
      :captain-document="selectedDocument"
      @close="handleRelatedResponseClose"
    />
    <CreateDocumentDialog
      v-if="showCreateDialog"
      ref="createDocumentDialog"
      :assistant-id="selectedAssistantId"
      @create-success="onCreateSuccess"
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
