<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import { useRouter } from 'vue-router';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import DeleteDialog from 'dashboard/components-next/aiagent/pageComponents/DeleteDialog.vue';
import BulkDeleteDialog from 'dashboard/components-next/aiagent/pageComponents/BulkDeleteDialog.vue';
import PageLayout from 'dashboard/components-next/aiagent/PageLayout.vue';
import AiagentPaywall from 'dashboard/components-next/aiagent/pageComponents/Paywall.vue';
import TopicSelector from 'dashboard/components-next/aiagent/pageComponents/TopicSelector.vue';
import ResponseCard from 'dashboard/components-next/aiagent/topic/ResponseCard.vue';
import CreateResponseDialog from 'dashboard/components-next/aiagent/pageComponents/response/CreateResponseDialog.vue';
import ResponsePageEmptyState from 'dashboard/components-next/aiagent/pageComponents/emptyStates/ResponsePageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import LimitBanner from 'dashboard/components-next/aiagent/pageComponents/response/LimitBanner.vue';

const router = useRouter();
const store = useStore();
const uiFlags = useMapGetter('aiagentResponses/getUIFlags');
const topics = useMapGetter('aiagentTopics/getRecords');
const responseMeta = useMapGetter('aiagentResponses/getMeta');
const responses = useMapGetter('aiagentResponses/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedResponse = ref(null);
const deleteDialog = ref(null);
const bulkDeleteDialog = ref(null);

const selectedStatus = ref('all');
const selectedTopic = ref('all');
const dialogType = ref('');
const { t } = useI18n();

const createDialog = ref(null);

const isStatusFilterOpen = ref(false);
const shouldShowDropdown = computed(() => {
  if (topics.value.length === 0) return false;

  return !isFetching.value;
});

const statusOptions = computed(() =>
  ['all', 'pending', 'approved'].map(key => ({
    label: t(`AIAGENT.RESPONSES.STATUS.${key.toUpperCase()}`),
    value: key,
    action: 'filter',
  }))
);

const selectedStatusLabel = computed(() => {
  const status = statusOptions.value.find(
    option => option.value === selectedStatus.value
  );
  return t('AIAGENT.RESPONSES.FILTER.STATUS', {
    selected: status ? status.label : '',
  });
});

const handleDelete = () => {
  deleteDialog.value.dialogRef.open();
};
const handleAccept = async () => {
  try {
    await store.dispatch('aiagentResponses/update', {
      id: selectedResponse.value.id,
      status: 'approved',
    });
    useAlert(t(`AIAGENT.RESPONSES.EDIT.APPROVE_SUCCESS_MESSAGE`));
  } catch (error) {
    const errorMessage =
      error?.message || t(`AIAGENT.RESPONSES.EDIT.ERROR_MESSAGE`);
    useAlert(errorMessage);
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

const fetchResponses = (page = 1) => {
  const filterParams = { page };
  if (selectedStatus.value !== 'all') {
    filterParams.status = selectedStatus.value;
  }
  if (selectedTopic.value !== 'all') {
    filterParams.topicId = selectedTopic.value;
  }
  store.dispatch('aiagentResponses/get', filterParams);
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

const handleCardHover = (isHovered, id) => {
  hoveredCard.value = isHovered ? id : null;
};

const handleCardSelect = id => {
  const selected = new Set(bulkSelectedIds.value);
  selected[selected.has(id) ? 'delete' : 'add'](id);
  bulkSelectedIds.value = selected;
};

const handleBulkApprove = async () => {
  try {
    await store.dispatch(
      'aiagentBulkActions/handleBulkApprove',
      Array.from(bulkSelectedIds.value)
    );

    // Clear selection
    bulkSelectedIds.value = new Set();
    useAlert(t('AIAGENT.RESPONSES.BULK_APPROVE.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error?.message || t('AIAGENT.RESPONSES.BULK_APPROVE.ERROR_MESSAGE')
    );
  }
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
  // Only fetch if no records left
  if (responses.value?.length === 0) {
    const page =
      responseMeta.value?.page > 1
        ? responseMeta.value.page - 1
        : responseMeta.value.page;
    fetchResponses(page);
  }

  // Clear selection
  bulkSelectedIds.value = new Set();
};

const handleStatusFilterChange = ({ value }) => {
  selectedStatus.value = value;
  isStatusFilterOpen.value = false;
  fetchResponses();
};

const handleTopicFilterChange = topic => {
  selectedTopic.value = topic;
  fetchResponses();
};

onMounted(() => {
  store.dispatch('aiagentTopics/get');
  fetchResponses();
});
</script>

<template>
  <PageLayout
    :total-count="responseMeta.totalCount"
    :current-page="responseMeta.page"
    :button-policy="['administrator']"
    :header-title="$t('AIAGENT.RESPONSES.HEADER')"
    :button-label="$t('AIAGENT.RESPONSES.ADD_NEW')"
    :is-fetching="isFetching"
    :is-empty="!responses.length"
    :show-pagination-footer="!isFetching && !!responses.length"
    :feature-flag="FEATURE_FLAGS.AIAGENT"
    @update:current-page="onPageChange"
    @click="handleCreate"
  >
    <template #knowMore>
      <FeatureSpotlightPopover
        :button-label="$t('AIAGENT.HEADER_KNOW_MORE')"
        :title="$t('AIAGENT.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
        :note="$t('AIAGENT.RESPONSES.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
        fallback-thumbnail="/assets/images/dashboard/aiagent/faqs-popover-light.svg"
        fallback-thumbnail-dark="/assets/images/dashboard/aiagent/faqs-popover-dark.svg"
        learn-more-url="https://chwt.app/aiagent-faq"
      />
    </template>

    <template #emptyState>
      <ResponsePageEmptyState @click="handleCreate" />
    </template>

    <template #paywall>
      <AiagentPaywall />
    </template>

    <template #controls>
      <div
        v-if="shouldShowDropdown"
        class="mb-4 -mt-3 flex justify-between items-center"
      >
        <div v-if="!bulkSelectionState.hasSelected" class="flex gap-3">
          <OnClickOutside @trigger="isStatusFilterOpen = false">
            <Button
              :label="selectedStatusLabel"
              icon="i-lucide-chevron-down"
              size="sm"
              color="slate"
              trailing-icon
              class="max-w-48"
              @click="isStatusFilterOpen = !isStatusFilterOpen"
            />

            <DropdownMenu
              v-if="isStatusFilterOpen"
              :menu-items="statusOptions"
              class="mt-2"
              @action="handleStatusFilterChange"
            />
          </OnClickOutside>
          <TopicSelector
            :topic-id="selectedTopic"
            @update="handleTopicFilterChange"
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
            class="flex items-center gap-3 ltr:pl-4 rtl:pr-4"
          >
            <div class="flex items-center gap-1.5">
              <Checkbox
                v-model="bulkCheckbox"
                :indeterminate="bulkSelectionState.isIndeterminate"
              />
              <span class="text-sm text-n-slate-10 tabular-nums">
                {{
                  $t('AIAGENT.RESPONSES.SELECTED', {
                    count: bulkSelectedIds.size,
                  })
                }}
              </span>
            </div>
            <div class="h-4 w-px bg-n-strong" />
            <div class="flex gap-2">
              <Button
                :label="$t('AIAGENT.RESPONSES.BULK_APPROVE_BUTTON')"
                sm
                slate
                @click="handleBulkApprove"
              />
              <Button
                :label="$t('AIAGENT.RESPONSES.BULK_DELETE_BUTTON')"
                sm
                slate
                @click="bulkDeleteDialog.dialogRef.open()"
              />
            </div>
          </div>
        </transition>
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
          :topic="response.topic"
          :documentable="response.documentable"
          :status="response.status"
          :created-at="response.created_at"
          :updated-at="response.updated_at"
          :is-selected="bulkSelectedIds.has(response.id)"
          :selectable="hoveredCard === response.id || bulkSelectedIds.size > 0"
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
