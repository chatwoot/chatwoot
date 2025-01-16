<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import ResponseCard from 'dashboard/components-next/captain/assistant/ResponseCard.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CreateResponseDialog from 'dashboard/components-next/captain/pageComponents/response/CreateResponseDialog.vue';
import ResponsePageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/ResponsePageEmptyState.vue';

const store = useStore();
const uiFlags = useMapGetter('captainResponses/getUIFlags');
const responseMeta = useMapGetter('captainResponses/getMeta');
const responses = useMapGetter('captainResponses/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedResponse = ref(null);
const deleteDialog = ref(null);

const selectedStatus = ref('all');
const selectedAssistant = ref('all');
const dialogType = ref('');
const { t } = useI18n();

const createDialog = ref(null);

const isStatusFilterOpen = ref(false);
const isAssistantFilterOpen = ref(false);

const isNotDefaultFilter = computed(
  () => selectedStatus.value !== 'all' || selectedAssistant.value !== 'all'
);

const shouldShowDropdown = computed(() => {
  // Show if filters are not default, regardless of responses
  if (isNotDefaultFilter.value) {
    return !isFetching.value;
  }

  // Otherwise, show only if we have responses and not fetching
  return !isFetching.value && responses.value.length > 0;
});

const statusOptions = computed(() =>
  ['all', 'pending', 'approved'].map(key => ({
    label: t(`CAPTAIN.RESPONSES.STATUS.${key.toUpperCase()}`),
    value: key,
    action: 'filter',
  }))
);

const selectedStatusLabel = computed(() => {
  const status = statusOptions.value.find(
    option => option.value === selectedStatus.value
  );
  return t('CAPTAIN.RESPONSES.FILTER.STATUS', {
    selected: status ? status.label : '',
  });
});

const assistants = useMapGetter('captainAssistants/getRecords');
const assistantOptions = computed(() => [
  {
    label: t(`CAPTAIN.RESPONSES.FILTER.ALL_ASSISTANTS`),
    value: 'all',
    action: 'filter',
  },
  ...assistants.value.map(assistant => ({
    value: assistant.id,
    label: assistant.name,
    action: 'filter',
  })),
]);

const selectedAssistantLabel = computed(() => {
  const assistant = assistantOptions.value.find(
    option => option.value === selectedAssistant.value
  );
  return t('CAPTAIN.RESPONSES.FILTER.ASSISTANT', {
    selected: assistant ? assistant.label : '',
  });
});

const handleDelete = () => {
  deleteDialog.value.dialogRef.open();
};
const handleAccept = async () => {
  try {
    await store.dispatch('captainResponses/update', {
      id: selectedResponse.value.id,
      status: 'approved',
    });
    useAlert(t(`CAPTAIN.RESPONSES.EDIT.APPROVE_SUCCESS_MESSAGE`));
  } catch (error) {
    const errorMessage =
      error?.message || t(`CAPTAIN.RESPONSES.EDIT.ERROR_MESSAGE`);
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

const handleCreateClose = () => {
  dialogType.value = '';
  selectedResponse.value = null;
};

const fetchResponses = (page = 1) => {
  const filterParams = {};
  if (selectedStatus.value !== 'all') {
    filterParams.status = selectedStatus.value;
  }
  if (selectedAssistant.value !== 'all') {
    filterParams.assistantId = selectedAssistant.value;
  }
  store.dispatch('captainResponses/get', { page, ...filterParams });
};

const onPageChange = page => fetchResponses(page);

const handleStatusFilterChange = ({ value }) => {
  selectedStatus.value = value;
  isStatusFilterOpen.value = false;
  fetchResponses();
};

const handleAssistantFilterChange = ({ value }) => {
  selectedAssistant.value = value;
  isAssistantFilterOpen.value = false;
  fetchResponses();
};

onMounted(() => {
  store.dispatch('captainAssistants/get');
  fetchResponses();
});
</script>

<template>
  <PageLayout
    :total-count="responseMeta.totalCount"
    :current-page="responseMeta.page"
    :header-title="$t('CAPTAIN.RESPONSES.HEADER')"
    :button-label="$t('CAPTAIN.RESPONSES.ADD_NEW')"
    :show-pagination-footer="!isFetching && !!responses.length"
    @update:current-page="onPageChange"
    @click="handleCreate"
  >
    <div v-if="shouldShowDropdown" class="mb-4 -mt-3 flex gap-3">
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

      <OnClickOutside @trigger="isAssistantFilterOpen = false">
        <Button
          :label="selectedAssistantLabel"
          icon="i-lucide-chevron-down"
          size="sm"
          color="slate"
          trailing-icon
          class="max-w-48"
          @click="isAssistantFilterOpen = !isAssistantFilterOpen"
        />

        <DropdownMenu
          v-if="isAssistantFilterOpen"
          :menu-items="assistantOptions"
          class="mt-2"
          @action="handleAssistantFilterChange"
        />
      </OnClickOutside>
    </div>
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <div v-else-if="responses.length" class="flex flex-col gap-4">
      <ResponseCard
        v-for="response in responses"
        :id="response.id"
        :key="response.id"
        :question="response.question"
        :answer="response.answer"
        :assistant="response.assistant"
        :status="response.status"
        :created-at="response.created_at"
        :updated-at="response.updated_at"
        @action="handleAction"
      />
    </div>

    <ResponsePageEmptyState
      v-else
      :title="$t('CAPTAIN.RESPONSES.EMPTY_STATE.TITLE')"
      :subtitle="$t('CAPTAIN.RESPONSES.EMPTY_STATE.SUBTITLE')"
      :button-label="$t('CAPTAIN.RESPONSES.ADD_NEW')"
      @click="handleCreate"
    />

    <DeleteDialog
      v-if="selectedResponse"
      ref="deleteDialog"
      :entity="selectedResponse"
      type="Responses"
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
