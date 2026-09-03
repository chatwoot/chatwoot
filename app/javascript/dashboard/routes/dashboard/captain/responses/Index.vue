<script setup>
import { computed, onUnmounted, ref, nextTick, watch } from 'vue';
import { useTimeoutFn } from '@vueuse/core';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { debounce } from '@chatwoot/utils';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePolicy } from 'dashboard/composables/usePolicy';
import CaptainResponseAPI from 'dashboard/api/captain/response';
import CaptainFaqImportsAPI from 'dashboard/api/captain/faqImports';

import Banner from 'dashboard/components-next/banner/Banner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
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
import ConversationUsageDrawer from 'dashboard/components-next/captain/pageComponents/ConversationUsageDrawer.vue';
import FaqImportDialog from 'dashboard/components-next/captain/pageComponents/response/FaqImportDialog.vue';

const router = useRouter();
const route = useRoute();
const store = useStore();
const { isOnChatwootCloud } = useAccount();
const { checkPermissions } = usePolicy();
const uiFlags = useMapGetter('captainResponses/getUIFlags');
const responseMeta = useMapGetter('captainResponses/getMeta');
const responses = useMapGetter('captainResponses/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedResponse = ref(null);
const usageResponse = ref(null);
const showResponseUsage = ref(false);
const deleteDialog = ref(null);
const bulkDeleteDialog = ref(null);

const dialogType = ref('');
const searchQuery = ref('');
const { t } = useI18n();

const createDialog = ref(null);
const faqImportDialog = ref(null);
const showFaqActions = ref(false);
const showFaqImportDialog = ref(false);
const latestFaqImport = ref(null);
let faqImportStatusTimer = null;

const { run: runFaqImportRequest, abort: abortFaqImportRequest } =
  useAbortableRequest();

const FAQ_IMPORT_POLL_INTERVAL = 5000;
const FAQ_IMPORT_STATUS_VISIBLE_FOR = 15000;
const FAQ_IMPORT_STATUS_CONFIG = {
  preparing: {
    icon: 'i-lucide-file-up',
    className: 'text-n-blue-11',
    title: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.PREPARING.TITLE'),
    description: counts =>
      t('CAPTAIN.RESPONSES.IMPORT.STATUS.PREPARING.DESCRIPTION', counts),
  },
  completed: {
    icon: 'i-lucide-circle-check',
    className: 'text-n-teal-11',
    title: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED.TITLE'),
    description: counts =>
      t('CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED.DESCRIPTION', counts),
  },
  completed_with_errors: {
    icon: 'i-lucide-triangle-alert',
    className: 'text-n-amber-11',
    title: () =>
      t('CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED_WITH_ERRORS.TITLE'),
    description: counts =>
      t(
        'CAPTAIN.RESPONSES.IMPORT.STATUS.COMPLETED_WITH_ERRORS.DESCRIPTION',
        counts
      ),
  },
  failed: {
    icon: 'i-lucide-circle-alert',
    className: 'text-n-ruby-11',
    title: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.FAILED.TITLE'),
    description: () => t('CAPTAIN.RESPONSES.IMPORT.STATUS.FAILED.DESCRIPTION'),
  },
};

const selectedAssistantId = computed(() => Number(route.params.assistantId));
const canManageFaqs = computed(() => checkPermissions(['administrator']));

const faqActionItems = computed(() => [
  {
    label: t('CAPTAIN.RESPONSES.CREATE_MANUALLY'),
    action: 'create',
    icon: 'i-lucide-square-pen',
  },
  {
    label: t('CAPTAIN.RESPONSES.IMPORT.ACTION'),
    action: 'import',
    icon: 'i-lucide-file-up',
    disabled: latestFaqImport.value?.status === 'preparing',
  },
]);

const suggestionCount = useMapGetter('captainFaqSuggestions/getOpenCount');

const faqImportStatus = computed(() => {
  const config = FAQ_IMPORT_STATUS_CONFIG[latestFaqImport.value?.status];
  const counts = {
    created: latestFaqImport.value?.created_count || 0,
    overwritten: latestFaqImport.value?.overwritten_count || 0,
    skipped: latestFaqImport.value?.skipped_count || 0,
  };

  return {
    icon: config?.icon,
    className: config?.className || 'text-n-slate-11',
    title: config?.title() || '',
    description: config?.description(counts) || '',
  };
});

const stopFaqImportStatusTimer = () => {
  if (faqImportStatusTimer) clearTimeout(faqImportStatusTimer);
  faqImportStatusTimer = null;
};

const displayFaqImportStatus = faqImport => {
  stopFaqImportStatusTimer();

  if (!faqImport || faqImport.status === 'preparing') {
    latestFaqImport.value = faqImport;
    return;
  }

  const completedAt = Date.parse(faqImport.completed_at);
  const remainingTime = Math.min(
    FAQ_IMPORT_STATUS_VISIBLE_FOR,
    FAQ_IMPORT_STATUS_VISIBLE_FOR - (Date.now() - completedAt)
  );

  if (!Number.isFinite(completedAt) || remainingTime <= 0) {
    latestFaqImport.value = null;
    return;
  }

  latestFaqImport.value = faqImport;
  faqImportStatusTimer = setTimeout(() => {
    latestFaqImport.value = null;
    faqImportStatusTimer = null;
  }, remainingTime);
};

const handleFaqImportOpen = () => {
  showFaqImportDialog.value = true;
  nextTick(() => faqImportDialog.value.dialogRef.open());
};

const toggleFaqActions = () => {
  if (!canManageFaqs.value) return;
  showFaqActions.value = !showFaqActions.value;
};

const handleFaqImportClose = () => {
  showFaqImportDialog.value = false;
};

const handleDelete = () => {
  deleteDialog.value.dialogRef.open();
};

const handleCreate = () => {
  dialogType.value = 'create';
  nextTick(() => createDialog.value.dialogRef.open());
};

const handleFaqAction = ({ action }) => {
  showFaqActions.value = false;
  if (action === 'import') {
    handleFaqImportOpen();
  } else {
    handleCreate();
  }
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

const handleShowResponseUsage = id => {
  usageResponse.value =
    responses.value.find(response => response.id === id) || null;
  showResponseUsage.value = Boolean(usageResponse.value);
};

const handleResponseUsageClose = () => {
  showResponseUsage.value = false;
};

const fetchResponseUsage = ({ resourceId, ...params }) =>
  CaptainResponseAPI.getDrilldown({ responseId: resourceId, ...params });

const updateURLWithFilters = (page, search) => {
  const query = {
    page: page || 1,
  };

  if (search) {
    query.search = search;
  }

  router.replace({ query });
};

const { run: runListRequest, abort: abortListRequest } = useAbortableRequest();

const fetchResponses = async (page = 1) => {
  const filterParams = { page };

  if (selectedAssistantId.value) {
    filterParams.assistantId = selectedAssistantId.value;
  }
  if (searchQuery.value) {
    filterParams.search = searchQuery.value;
  }

  // Update URL with current filters
  updateURLWithFilters(page, searchQuery.value);

  store.dispatch('captainResponses/setFetchingList', true);

  try {
    const response = await runListRequest(signal =>
      CaptainResponseAPI.get({ ...filterParams, signal })
    );

    if (!response) return;

    store.dispatch('captainResponses/setRecords', {
      records: response.data.payload,
      meta: response.data.meta,
    });
    store.dispatch('captainResponses/setFetchingList', false);
  } catch (error) {
    useAlert(error?.message || t('CAPTAIN.RESPONSES.ERRORS.LOAD'));
    store.dispatch('captainResponses/setFetchingList', false);
  }
};

let faqImportPollingControls;

const fetchLatestFaqImport = async () => {
  const assistantId = selectedAssistantId.value;

  try {
    const response = await runFaqImportRequest(signal =>
      CaptainFaqImportsAPI.latest({ assistantId, signal })
    );
    if (!response || assistantId !== selectedAssistantId.value) return;

    const { data } = response;

    const previousStatus = latestFaqImport.value?.status;
    displayFaqImportStatus(data);
    const isRecentTerminalImport = Boolean(
      data &&
        data.status !== 'preparing' &&
        latestFaqImport.value?.id === data.id
    );

    if (data?.status === 'preparing') {
      faqImportPollingControls.start();
    } else {
      faqImportPollingControls.stop();
      if (previousStatus === 'preparing' || isRecentTerminalImport) {
        fetchResponses(responseMeta.value?.page || 1);
      }
    }
  } catch {
    if (latestFaqImport.value?.status === 'preparing') {
      faqImportPollingControls.start();
    }
  }
};

faqImportPollingControls = useTimeoutFn(
  fetchLatestFaqImport,
  FAQ_IMPORT_POLL_INTERVAL,
  { immediate: false }
);

const handleFaqImportConfirmed = faqImport => {
  abortFaqImportRequest();
  displayFaqImportStatus(faqImport);
  faqImportPollingControls.stop();
  if (faqImport?.status === 'preparing') {
    faqImportPollingControls.start();
  } else if (faqImport) {
    fetchResponses(responseMeta.value?.page || 1);
  }
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

  showResponseUsage.value = false;
  usageResponse.value = null;

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

const handleSearchInput = () => {
  abortListRequest();
  debouncedSearch();
};

const initializeFromURL = () => {
  searchQuery.value = route.query.search || '';
  const pageFromURL = parseInt(route.query.page, 10) || 1;
  fetchResponses(pageFromURL);
};

const navigateToFaqSuggestions = () => {
  router.push({
    name: 'captain_assistants_faq_suggestions',
    params: {
      accountId: route.params.accountId,
      assistantId: selectedAssistantId.value,
    },
  });
};

watch(
  selectedAssistantId,
  () => {
    faqImportPollingControls.stop();
    stopFaqImportStatusTimer();
    abortFaqImportRequest();
    latestFaqImport.value = null;
    showFaqActions.value = false;
    showFaqImportDialog.value = false;
    selectedResponse.value = null;
    usageResponse.value = null;
    showResponseUsage.value = false;
    bulkSelectedIds.value = new Set();
    store.dispatch('captainResponses/setRecords', {
      records: [],
      meta: { page: 1, total_count: 0 },
    });
    initializeFromURL();
    store.dispatch(
      'captainFaqSuggestions/fetchOpenCount',
      selectedAssistantId.value
    );
    if (canManageFaqs.value) fetchLatestFaqImport();
  },
  { immediate: true }
);

onUnmounted(() => {
  faqImportPollingControls.stop();
  stopFaqImportStatusTimer();
  abortFaqImportRequest();
  store.dispatch('captainResponses/setFetchingList', false);
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
    @click="toggleFaqActions"
    @close="showFaqActions = false"
  >
    <template #action>
      <DropdownMenu
        v-if="canManageFaqs && showFaqActions"
        :menu-items="faqActionItems"
        class="mt-1 min-w-48 ltr:right-0 rtl:left-0 top-full"
        @action="handleFaqAction"
      />
    </template>

    <template #controls>
      <section
        v-if="latestFaqImport"
        data-testid="faq-import-status"
        :data-status="latestFaqImport.status"
        role="status"
        aria-live="polite"
        class="mb-4"
      >
        <h3 class="mb-2 text-sm font-medium text-n-slate-12">
          {{ $t('CAPTAIN.RESPONSES.IMPORT.SECTION_TITLE') }}
        </h3>
        <div
          class="flex items-start gap-3 rounded-xl border border-n-weak bg-n-solid-1 px-4 py-3"
        >
          <Icon
            :icon="faqImportStatus.icon"
            class="mt-0.5 size-4 shrink-0"
            :class="faqImportStatus.className"
          />
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
              <span class="text-sm font-medium text-n-slate-12">
                {{ faqImportStatus.title }}
              </span>
              <span class="truncate text-xs text-n-slate-10">
                {{ latestFaqImport.original_filename }}
              </span>
            </div>
            <p class="mb-0 mt-1 text-xs text-n-slate-11">
              {{ faqImportStatus.description }}
            </p>
          </div>
        </div>
      </section>
    </template>

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
          @input="handleSearchInput"
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
        v-if="suggestionCount > 0"
        color="blue"
        class="mb-4 -mt-3"
        :action-label="$t('CAPTAIN.RESPONSES.SUGGESTIONS_BANNER.ACTION')"
        @action="navigateToFaqSuggestions"
      >
        {{ $t('CAPTAIN.RESPONSES.SUGGESTIONS_BANNER.TITLE') }}
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
          :used-in-conversations-count="response.used_in_conversations_count"
          :is-selected="bulkSelectedIds.has(response.id)"
          :selectable="hoveredCard === response.id || bulkSelectedIds.size > 0"
          :show-menu="!bulkSelectedIds.has(response.id)"
          :show-actions="false"
          @action="handleAction"
          @navigate="handleNavigationAction"
          @select="handleCardSelect"
          @hover="isHovered => handleCardHover(isHovered, response.id)"
          @view-conversations="handleShowResponseUsage"
        />
      </div>
    </template>

    <ConversationUsageDrawer
      :open="showResponseUsage"
      :resource-id="usageResponse?.id"
      :title="usageResponse?.question || ''"
      :conversation-count="usageResponse?.used_in_conversations_count || 0"
      :fetcher="fetchResponseUsage"
      empty-state-key="CAPTAIN.RESPONSES.NO_USED_CONVERSATIONS"
      @close="handleResponseUsageClose"
    />

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
      type="AssistantResponse"
      @delete-success="onBulkDeleteSuccess"
    />

    <CreateResponseDialog
      v-if="dialogType"
      ref="createDialog"
      :type="dialogType"
      :selected-response="selectedResponse"
      @close="handleCreateClose"
    />

    <FaqImportDialog
      v-if="showFaqImportDialog"
      ref="faqImportDialog"
      :assistant-id="selectedAssistantId"
      @close="handleFaqImportClose"
      @confirmed="handleFaqImportConfirmed"
    />
  </PageLayout>
</template>
