<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { debounce } from '@chatwoot/utils';
import { useAccount } from 'dashboard/composables/useAccount';

import Banner from 'dashboard/components-next/banner/Banner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import BulkDeleteDialog from 'dashboard/components-next/captain/pageComponents/BulkDeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import AssistantSelector from 'dashboard/components-next/captain/pageComponents/AssistantSelector.vue';
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
const assistants = useMapGetter('captainAssistants/getRecords');
const responseMeta = useMapGetter('captainResponses/getMeta');
const responses = useMapGetter('captainResponses/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedResponse = ref(null);
const deleteDialog = ref(null);
const bulkDeleteDialog = ref(null);

const selectedAssistant = ref('all');
const dialogType = ref('');
const searchQuery = ref('');
const { t } = useI18n();

const createDialog = ref(null);

const shouldShowDropdown = computed(() => {
  if (assistants.value.length === 0) return false;

  return !isFetching.value;
});

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

  if (selectedAssistant.value !== 'all') {
    filterParams.assistantId = selectedAssistant.value;
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

const bulkSelectionState = computed(() => {
  const selectedCount = bulkSelectedIds.value.size;
  const totalCount = responses.value?.length || 0;

  return {
    hasSelected: selectedCount > 0,
    isIndeterminate: selectedCount > 0 && selectedCount < totalCount,
    allSelected: totalCount > 0 && selectedCount === totalCount,
  };
});

const bulkCheckbox = computed({
  get: () => bulkSelectionState.value.allSelected,
  set: value => {
    bulkSelectedIds.value = value
      ? new Set(responses.value.map(r => r.id))
      : new Set();
  },
});

const buildSelectedCountLabel = computed(() => {
  const count = responses.value?.length || 0;
  return bulkSelectionState.value.allSelected
    ? t('CAPTAIN.RESPONSES.UNSELECT_ALL', { count })
    : t('CAPTAIN.RESPONSES.SELECT_ALL', { count });
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
  // Store current selection state before fetching new page
  const wasAllPageSelected = bulkSelectionState.value.allSelected;
  const hadPartialSelection = bulkSelectedIds.value.size > 0;

  fetchResponses(page);

  // Reset selection if we had any selections on page change
  if (wasAllPageSelected || hadPartialSelection) {
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

const handleAssistantFilterChange = assistant => {
  selectedAssistant.value = assistant;
  fetchResponses(1);
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
  router.push({ name: 'captain_responses_pending' });
};

onMounted(() => {
  store.dispatch('captainAssistants/get');
  initializeFromURL();
  store.dispatch('captainResponses/fetchPendingCount');
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

    <template #subHeader>
      <div
        v-if="shouldShowDropdown"
        class="mb-2 flex justify-between items-center py-1"
        :class="{
          'ltr:pl-3 rtl:pr-3 ltr:pr-1 rtl:pl-1 rounded-lg outline outline-1 outline-n-weak bg-n-solid-3 w-fit':
            bulkSelectionState.hasSelected,
        }"
      >
        <div
          v-if="!bulkSelectionState.hasSelected"
          class="flex gap-3 justify-between w-full items-center"
        >
          <div class="flex items-center gap-3">
            <AssistantSelector
              :assistant-id="selectedAssistant"
              @update="handleAssistantFilterChange"
            />
          </div>
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

        <transition
          name="slide-fade"
          enter-active-class="transition-all duration-300 ease-out"
          enter-from-class="opacity-0 transform ltr:-translate-x-4 rtl:translate-x-4"
          enter-to-class="opacity-100 transform translate-x-0"
          leave-active-class="hidden opacity-0"
        >
          <div
            v-if="bulkSelectionState.hasSelected"
            class="flex items-center gap-3"
          >
            <div class="flex items-center gap-3">
              <div class="flex items-center gap-1.5">
                <Checkbox
                  v-model="bulkCheckbox"
                  :indeterminate="bulkSelectionState.isIndeterminate"
                />
                <span class="text-sm text-n-slate-12 font-medium tabular-nums">
                  {{ buildSelectedCountLabel }}
                </span>
              </div>
              <span class="text-sm text-n-slate-10 tabular-nums">
                {{
                  $t('CAPTAIN.RESPONSES.SELECTED', {
                    count: bulkSelectedIds.size,
                  })
                }}
              </span>
            </div>
            <div class="h-4 w-px bg-n-strong" />
            <div class="flex gap-3 items-center">
              <Button
                :label="$t('CAPTAIN.RESPONSES.BULK_DELETE_BUTTON')"
                sm
                ruby
                ghost
                class="!px-1.5"
                icon="i-lucide-trash"
                @click="bulkDeleteDialog.dialogRef.open()"
              />
            </div>
          </div>
        </transition>
      </div>
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
