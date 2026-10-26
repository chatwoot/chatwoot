<script setup>
import { computed, watch, ref, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useAdmin } from 'dashboard/composables/useAdmin';

import ToolsPageLayout from 'dashboard/components-next/captain/pageComponents/tools/ToolsPageLayout.vue';
import CustomToolsPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue';
import CreateCustomToolDialog from 'dashboard/components-next/captain/pageComponents/customTool/CreateCustomToolDialog.vue';
import CustomToolCard from 'dashboard/components-next/captain/pageComponents/customTool/CustomToolCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ToolsetInstallFlow from 'dashboard/components-next/captain/pageComponents/customTool/ToolsetInstallFlow.vue';
import AssistantToolsBanner from 'dashboard/components-next/captain/pageComponents/customTool/AssistantToolsBanner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Policy from 'dashboard/components/policy.vue';
import { TOOL_SOURCES } from './constants';
import {
  fetchToolsCatalog,
  installedToolsetKey,
} from 'dashboard/api/captain/toolsCatalog';
import ToolsManifestAPI from 'dashboard/api/captain/toolsManifest';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';

const props = defineProps({
  source: {
    type: String,
    required: true,
    validator: value => Object.values(TOOL_SOURCES).includes(value),
  },
});

const store = useStore();
const route = useRoute();
const router = useRouter();
const assistantId = computed(() => route.params.assistantId);
const { t } = useI18n();
const { shouldShowPaywall } = usePolicy();
const { isAdmin } = useAdmin();

const uiFlags = useMapGetter('captainCustomTools/getUIFlags');
const globalConfig = useMapGetter('globalConfig/get');
const { run, isPending: isFetchingTools } = useAbortableRequest();
const records = useMapGetter('captainCustomTools/getRecords');
const isInstalledPage = computed(() => props.source === TOOL_SOURCES.INSTALLED);
const customTools = computed(() =>
  records.value.filter(
    tool =>
      tool.assistant_id === Number(assistantId.value) &&
      !!tool.source_metadata === isInstalledPage.value
  )
);
// Toolset names and logos come from the catalog. Installs keep only the folder, which is the fallback name.
const catalogEntries = ref(new Map());
const loadCatalogNames = async () => {
  const catalogURL = globalConfig.value.captainToolsCatalogURL;
  if (!isInstalledPage.value || !catalogURL || catalogEntries.value.size)
    return;
  try {
    const catalog = await fetchToolsCatalog(catalogURL);
    catalogEntries.value = new Map(
      catalog.toolsets.map(toolset => [
        installedToolsetKey(toolset.source),
        toolset,
      ])
    );
  } catch {
    catalogEntries.value = new Map();
  }
};
// Installed tools are grouped by the toolset they came from
const toolsets = computed(() => {
  const groups = new Map();
  customTools.value.forEach(tool => {
    const { repository, path, version } = tool.source_metadata;
    const key = `${repository}/${path}`;
    if (!groups.has(key))
      groups.set(key, {
        key,
        source: key,
        name: catalogEntries.value.get(key)?.name || path,
        logoUrl: catalogEntries.value.get(key)?.logo_url,
        logoDarkUrl: catalogEntries.value.get(key)?.logo_dark_url,
        version,
        tools: [],
      });
    groups.get(key).tools.push(tool);
  });
  return [...groups.values()];
});
const layoutRef = ref(null);
const isFetching = computed(
  () => uiFlags.value.fetchingList || isFetchingTools.value
);
const customToolsMeta = useMapGetter('captainCustomTools/getMeta');

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

const fetchCustomTools = (page = 1) =>
  run(signal =>
    store.dispatch('captainCustomTools/get', {
      assistantId: assistantId.value,
      source: props.source,
      page,
      signal,
    })
  );

const onPageChange = page => fetchCustomTools(page);

const openCatalog = () =>
  router.push({
    name: 'captain_tools_explore',
    params: {
      accountId: route.params.accountId,
      assistantId: assistantId.value,
    },
  });

const openCreateDialog = () => {
  dialogType.value = 'create';
  selectedTool.value = null;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const openToolPanel = (type, tool) => {
  dialogType.value = type;
  selectedTool.value = tool;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const handleDelete = tool => {
  selectedTool.value = tool;
  nextTick(() => deleteDialogRef.value.dialogRef.open());
};

const handleAction = ({ action, id }) => {
  const tool = customTools.value.find(item => item.id === id);
  if (action === 'edit' || action === 'view') {
    openToolPanel(action, tool);
  } else if (action === 'delete') {
    handleDelete(tool);
  }
};

const updateCustomToolStatus = async ({ id, enabled }) => {
  try {
    await store.dispatch('captainCustomTools/update', {
      id,
      enabled,
      assistantId: assistantId.value,
    });
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
      const tool = await store.dispatch('captainCustomTools/show', {
        id,
        assistantId: assistantId.value,
      });
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

const removeDialogRef = ref(null);
const toolsetToRemove = ref(null);
const isRemovingToolset = ref(false);

const confirmRemoveToolset = toolset => {
  toolsetToRemove.value = toolset;
  nextTick(() => removeDialogRef.value.open());
};

const removeToolset = async () => {
  const toolset = toolsetToRemove.value;
  isRemovingToolset.value = true;
  try {
    await ToolsManifestAPI.uninstall({
      assistantId: assistantId.value,
      source: toolset.source,
    });
    useAlert(
      t('CAPTAIN.TOOLS_PAGES.INSTALLED.REMOVE.SUCCESS', { name: toolset.name })
    );
    removeDialogRef.value.close();
    fetchCustomTools();
    layoutRef.value?.refreshCounts();
  } catch (error) {
    useAlert(
      parseAPIErrorResponse(error) ||
        t('CAPTAIN.TOOLS_PAGES.INSTALLED.REMOVE.ERROR')
    );
  } finally {
    isRemovingToolset.value = false;
  }
};

const handleDialogClose = () => {
  dialogType.value = '';
  selectedTool.value = null;
};

const handleToolCreated = () => {
  fetchCustomTools();
  layoutRef.value?.refreshCounts();
};

// Install links land here with ?install=<source>; another assistant's tools load when the route changes
const onToolsetInstalled = installedAssistantId => {
  if (installedAssistantId !== Number(assistantId.value)) return;
  fetchCustomTools();
  layoutRef.value?.refreshCounts();
};

const finishToolsetInstall = installedAssistantId =>
  router.replace({
    name: 'captain_tools_installed',
    params: {
      accountId: route.params.accountId,
      assistantId: installedAssistantId,
    },
  });

const onDeleteSuccess = () => {
  selectedTool.value = null;
  layoutRef.value?.refreshCounts();
  if (customTools.value.length === 0 && customToolsMeta.value.page > 1) {
    onPageChange(customToolsMeta.value.page - 1);
  } else {
    // Refresh current page
    fetchCustomTools(customToolsMeta.value.page);
  }
};

// On a full reload account features load after mount, so the paywall briefly shows;
// watching it too fetches the tools once access resolves, not only when the assistant changes
const showPaywall = computed(() =>
  shouldShowPaywall(FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS)
);

watch(
  [assistantId, showPaywall, () => props.source],
  () => {
    if (showPaywall.value) return;
    fetchCustomTools();
    loadCatalogNames();
  },
  { immediate: true }
);
</script>

<template>
  <ToolsPageLayout
    ref="layoutRef"
    :heading="
      isInstalledPage
        ? $t('CAPTAIN.TOOLS_PAGES.INSTALLED.HEADING')
        : $t('CAPTAIN.TOOLS_PAGES.CUSTOM.HEADING')
    "
    :description="
      isInstalledPage
        ? $t('CAPTAIN.TOOLS_PAGES.INSTALLED.DESCRIPTION')
        : $t('CAPTAIN.TOOLS_PAGES.CUSTOM.DESCRIPTION')
    "
    :button-label="isInstalledPage ? '' : $t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW')"
    :total-count="customToolsMeta.totalCount"
    :current-page="customToolsMeta.page"
    :show-pagination-footer="!isFetching && !!customTools.length"
    :is-fetching="isFetching"
    :is-empty="!customTools.length"
    @update:current-page="onPageChange"
    @click="openCreateDialog"
  >
    <template #headerActions>
      <Policy
        v-if="
          isInstalledPage &&
          globalConfig.captainToolsManifestEnabled &&
          !shouldShowPaywall(FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS)
        "
        :permissions="['administrator']"
      >
        <Button
          :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.BUTTON')"
          icon="i-lucide-blocks"
          size="sm"
          faded
          slate
          @click="openCatalog"
        />
      </Policy>
    </template>

    <template #emptyState>
      <div
        v-if="isInstalledPage"
        class="flex flex-col items-start gap-3 p-6 rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
      >
        <span class="text-sm text-n-slate-11">
          {{ $t('CAPTAIN.TOOLS_PAGES.INSTALLED.EMPTY') }}
        </span>
        <Button
          v-if="globalConfig.captainToolsManifestEnabled"
          :label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.BUTTON')"
          icon="i-lucide-blocks"
          size="sm"
          @click="openCatalog"
        />
      </div>
      <CustomToolsPageEmptyState v-else @click="openCreateDialog" />
    </template>

    <template #controls>
      <AssistantToolsBanner v-if="!isInstalledPage" />
    </template>

    <template #body>
      <div v-if="isInstalledPage" class="flex flex-col gap-6">
        <section
          v-for="toolset in toolsets"
          :key="toolset.key"
          class="flex flex-col gap-3"
        >
          <div class="flex items-center gap-2">
            <template v-if="toolset.logoUrl">
              <img
                :src="toolset.logoUrl"
                alt=""
                class="object-contain rounded size-5 shrink-0 dark:hidden"
              />
              <img
                :src="toolset.logoDarkUrl || toolset.logoUrl"
                alt=""
                class="hidden object-contain rounded size-5 shrink-0 dark:block"
              />
            </template>
            <h3 class="m-0 text-sm font-medium text-n-slate-12">
              {{ toolset.name }}
            </h3>
            <span class="text-xs text-n-slate-11">
              {{
                $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.VERSION', {
                  version: toolset.version,
                })
              }}
            </span>
            <Policy
              :permissions="['administrator']"
              class="flex items-center ms-auto"
            >
              <Button
                :label="$t('CAPTAIN.TOOLS_PAGES.INSTALLED.REMOVE.BUTTON')"
                icon="i-lucide-trash"
                size="xs"
                ghost
                slate
                class="!text-n-slate-9 hover:!text-n-ruby-11 hover:!bg-transparent"
                @click="confirmRemoveToolset(toolset)"
              />
            </Policy>
          </div>
          <!-- One line per tool. The details open from the tool name. -->
          <ul
            class="m-0 list-none divide-y rounded-xl outline outline-1 outline-n-weak divide-n-weak"
          >
            <li
              v-for="tool in toolset.tools"
              :key="tool.id"
              class="flex items-center gap-3 px-4 py-2.5"
            >
              <button
                type="button"
                class="p-0 text-sm font-medium truncate text-start text-n-slate-12 hover:underline shrink-0 max-w-[40%]"
                @click="handleAction({ action: 'view', id: tool.id })"
              >
                {{ tool.title }}
              </button>
              <span class="flex-1 min-w-0 text-sm truncate text-n-slate-11">
                {{ tool.description }}
              </span>
              <Policy
                as="span"
                :permissions="['administrator']"
                class="inline-flex items-center shrink-0"
              >
                <Switch
                  :model-value="tool.enabled"
                  :disabled="pendingToggleIds.has(tool.id)"
                  :aria-label="
                    $t('CAPTAIN.CUSTOM_TOOLS.STATUS.TOGGLE', {
                      title: tool.title,
                    })
                  "
                  @update:model-value="
                    toggleCustomTool({ id: tool.id, enabled: $event })
                  "
                />
              </Policy>
            </li>
          </ul>
        </section>
      </div>
      <div v-else class="flex flex-col gap-4">
        <CustomToolCard
          v-for="tool in customTools"
          :id="tool.id"
          :key="tool.id"
          :title="tool.title"
          :description="tool.description"
          :auth-type="tool.auth_type"
          :enabled="tool.enabled"
          :source-metadata="tool.source_metadata"
          :is-updating="pendingToggleIds.has(tool.id)"
          :created-at="tool.created_at"
          :updated-at="tool.updated_at"
          @action="handleAction"
          @toggle="toggleCustomTool"
        />
      </div>
    </template>
  </ToolsPageLayout>

  <ToolsetInstallFlow
    v-if="isInstalledPage && isAdmin && !showPaywall && route.query.install"
    :source="route.query.install"
    :assistant-id="assistantId"
    @installed="onToolsetInstalled"
    @done="finishToolsetInstall"
  />

  <CreateCustomToolDialog
    v-if="dialogType"
    ref="createDialogRef"
    :type="dialogType"
    :selected-tool="selectedTool"
    @close="handleDialogClose"
    @created="handleToolCreated"
  />

  <DeleteDialog
    v-if="selectedTool"
    ref="deleteDialogRef"
    :entity="selectedTool"
    :delete-payload="{ id: selectedTool.id, assistantId }"
    type="CustomTools"
    translation-key="CUSTOM_TOOLS"
    @delete-success="onDeleteSuccess"
  />

  <Dialog
    ref="removeDialogRef"
    type="alert"
    :title="
      t('CAPTAIN.TOOLS_PAGES.INSTALLED.REMOVE.TITLE', {
        name: toolsetToRemove?.name,
      })
    "
    :description="
      t('CAPTAIN.TOOLS_PAGES.INSTALLED.REMOVE.DESCRIPTION', {
        count: toolsetToRemove?.tools.length,
      })
    "
    :confirm-button-label="t('CAPTAIN.TOOLS_PAGES.INSTALLED.REMOVE.CONFIRM')"
    :is-loading="isRemovingToolset"
    @confirm="removeToolset"
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
