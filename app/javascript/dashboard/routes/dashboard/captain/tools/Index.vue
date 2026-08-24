<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { usePolicy } from 'dashboard/composables/usePolicy';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import CustomToolsPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue';
import CreateCustomToolDialog from 'dashboard/components-next/captain/pageComponents/customTool/CreateCustomToolDialog.vue';
import CustomToolCard from 'dashboard/components-next/captain/pageComponents/customTool/CustomToolCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const store = useStore();
const { t } = useI18n();
const { isFeatureFlagEnabled, shouldShowPaywall } = usePolicy();

const SOFT_LIMIT = 10;
const isV2 = computed(() => isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN_V2));

const uiFlags = useMapGetter('captainCustomTools/getUIFlags');
const customTools = useMapGetter('captainCustomTools/getRecords');
const isFetching = computed(() => uiFlags.value.fetchingList);
const customToolsMeta = useMapGetter('captainCustomTools/getMeta');

const showSoftLimitWarning = computed(
  () => !isV2.value && customToolsMeta.value.totalCount > SOFT_LIMIT
);

const createDialogRef = ref(null);
const deleteDialogRef = ref(null);
const disableDialogRef = ref(null);
const selectedTool = ref(null);
const dialogType = ref('');
const pendingToggleIds = ref(new Set());
const pendingDisable = ref(null);
const isDisableSaving = ref(false);

const disableConfirmationTitle = computed(() =>
  t('CAPTAIN.CUSTOM_TOOLS.DISABLE_CONFIRMATION.TITLE', {
    title: pendingDisable.value?.title,
  })
);

const disableConfirmationDescription = computed(() => {
  const count = pendingDisable.value?.enabledScenariosCount || 0;
  return count === 1
    ? t('CAPTAIN.CUSTOM_TOOLS.DISABLE_CONFIRMATION.DESCRIPTION_ONE', {
        count,
      })
    : t('CAPTAIN.CUSTOM_TOOLS.DISABLE_CONFIRMATION.DESCRIPTION_OTHER', {
        count,
      });
});

const setTogglePending = (id, isPending) => {
  const pendingIds = new Set(pendingToggleIds.value);
  if (isPending) {
    pendingIds.add(id);
  } else {
    pendingIds.delete(id);
  }
  pendingToggleIds.value = pendingIds;
};

const fetchCustomTools = (page = 1) => {
  store.dispatch('captainCustomTools/get', { page });
};

const onPageChange = page => fetchCustomTools(page);

const openCreateDialog = () => {
  dialogType.value = 'create';
  selectedTool.value = null;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const handleEdit = tool => {
  dialogType.value = 'edit';
  selectedTool.value = tool;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const handleDelete = tool => {
  selectedTool.value = tool;
  nextTick(() => deleteDialogRef.value.dialogRef.open());
};

const handleAction = ({ action, id }) => {
  const tool = customTools.value.find(item => item.id === id);
  if (action === 'edit') {
    handleEdit(tool);
  } else if (action === 'delete') {
    handleDelete(tool);
  }
};

const updateCustomToolStatus = async ({ id, enabled }) => {
  try {
    await store.dispatch('captainCustomTools/update', { id, enabled });
    const successMessage = enabled
      ? t('CAPTAIN.CUSTOM_TOOLS.TOGGLE.ENABLED')
      : t('CAPTAIN.CUSTOM_TOOLS.TOGGLE.DISABLED');
    useAlert(successMessage);
    return true;
  } catch {
    useAlert(t('CAPTAIN.CUSTOM_TOOLS.TOGGLE.ERROR'));
    return false;
  }
};

const toggleCustomTool = async ({ id, enabled }) => {
  if (pendingToggleIds.value.has(id)) return;

  setTogglePending(id, true);

  if (!enabled) {
    try {
      const tool = await store.dispatch('captainCustomTools/show', id);
      if (tool.enabled_scenarios_count > 0) {
        pendingDisable.value = {
          id,
          enabled,
          title: tool.title,
          enabledScenariosCount: tool.enabled_scenarios_count,
        };
        await nextTick();
        disableDialogRef.value?.open();
        return;
      }
    } catch {
      useAlert(t('CAPTAIN.CUSTOM_TOOLS.TOGGLE.ERROR'));
      setTogglePending(id, false);
      return;
    }
  }

  await updateCustomToolStatus({ id, enabled });
  setTogglePending(id, false);
};

const handleDisableConfirm = async () => {
  if (!pendingDisable.value) return;

  isDisableSaving.value = true;
  const updated = await updateCustomToolStatus(pendingDisable.value);
  isDisableSaving.value = false;

  if (updated) disableDialogRef.value?.close();
};

const handleDisableDialogClose = () => {
  if (pendingDisable.value) {
    setTogglePending(pendingDisable.value.id, false);
  }
  pendingDisable.value = null;
  isDisableSaving.value = false;
};

const handleDialogClose = () => {
  dialogType.value = '';
  selectedTool.value = null;
};

const onDeleteSuccess = () => {
  selectedTool.value = null;
  // Check if page will be empty after deletion
  if (customTools.value.length === 1 && customToolsMeta.value.page > 1) {
    // Go to previous page if current page will be empty
    onPageChange(customToolsMeta.value.page - 1);
  } else {
    // Refresh current page
    fetchCustomTools(customToolsMeta.value.page);
  }
};

onMounted(() => {
  if (!shouldShowPaywall(FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS)) {
    fetchCustomTools();
  }
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.CUSTOM_TOOLS.HEADER')"
    :button-label="$t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW')"
    :button-policy="['administrator']"
    :feature-flag="FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS"
    :total-count="customToolsMeta.totalCount"
    :current-page="customToolsMeta.page"
    :show-pagination-footer="!isFetching && !!customTools.length"
    :is-fetching="isFetching"
    :is-empty="!customTools.length"
    :show-know-more="false"
    @update:current-page="onPageChange"
    @click="openCreateDialog"
  >
    <template #paywall>
      <CaptainPaywall feature-prefix="CAPTAIN.CUSTOM_TOOLS" />
    </template>

    <template #emptyState>
      <CustomToolsPageEmptyState @click="openCreateDialog" />
    </template>

    <template #body>
      <div class="flex flex-col gap-4">
        <div
          v-if="showSoftLimitWarning"
          class="flex items-center gap-2 px-4 py-3 text-sm rounded-lg bg-n-amber-2 text-n-amber-11"
        >
          <span class="i-lucide-triangle-alert size-4 shrink-0" />
          {{ $t('CAPTAIN.CUSTOM_TOOLS.SOFT_LIMIT_WARNING') }}
        </div>
        <CustomToolCard
          v-for="tool in customTools"
          :id="tool.id"
          :key="tool.id"
          :title="tool.title"
          :description="tool.description"
          :endpoint-url="tool.endpoint_url"
          :http-method="tool.http_method"
          :auth-type="tool.auth_type"
          :param-schema="tool.param_schema"
          :enabled="tool.enabled"
          :is-updating="pendingToggleIds.has(tool.id)"
          :created-at="tool.created_at"
          :updated-at="tool.updated_at"
          @action="handleAction"
          @toggle="toggleCustomTool"
        />
      </div>
    </template>
  </PageLayout>

  <CreateCustomToolDialog
    v-if="dialogType"
    ref="createDialogRef"
    :type="dialogType"
    :selected-tool="selectedTool"
    @close="handleDialogClose"
  />

  <DeleteDialog
    v-if="selectedTool"
    ref="deleteDialogRef"
    :entity="selectedTool"
    type="CustomTools"
    translation-key="CUSTOM_TOOLS"
    @delete-success="onDeleteSuccess"
  />

  <Dialog
    ref="disableDialogRef"
    type="alert"
    :title="disableConfirmationTitle"
    :description="disableConfirmationDescription"
    :confirm-button-label="
      t('CAPTAIN.CUSTOM_TOOLS.DISABLE_CONFIRMATION.CONFIRM')
    "
    :is-loading="isDisableSaving"
    @confirm="handleDisableConfirm"
    @close="handleDisableDialogClose"
  />
</template>
