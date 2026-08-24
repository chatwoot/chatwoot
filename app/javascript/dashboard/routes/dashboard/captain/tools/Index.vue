<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { CAPTAIN_TOOL_CATALOG_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import CustomToolsPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue';
import CreateCustomToolDialog from 'dashboard/components-next/captain/pageComponents/customTool/CreateCustomToolDialog.vue';
import CustomToolCard from 'dashboard/components-next/captain/pageComponents/customTool/CustomToolCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import InstalledGroup from 'dashboard/components-next/captain/pageComponents/toolCatalog/InstalledGroup.vue';
import ProviderCard from 'dashboard/components-next/captain/pageComponents/toolCatalog/ProviderCard.vue';

import { groupCatalogTools, groupCustomTools } from './catalogGrouping';

const store = useStore();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { checkPermissions, isFeatureFlagEnabled, shouldShowPaywall } =
  usePolicy();

const SOFT_LIMIT = 10;
const isV2 = computed(() => isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN_V2));
const catalogEnabled = computed(() =>
  isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN_TOOL_CATALOG)
);
const canManageCatalog = computed(
  () => catalogEnabled.value && checkPermissions(['administrator'])
);
const pageFeatureFlag = computed(() =>
  catalogEnabled.value
    ? FEATURE_FLAGS.CAPTAIN_TOOL_CATALOG
    : FEATURE_FLAGS.CAPTAIN_CUSTOM_TOOLS
);

const customToolsUIFlags = useMapGetter('captainCustomTools/getUIFlags');
const customTools = useMapGetter('captainCustomTools/getRecords');
const customToolsMeta = useMapGetter('captainCustomTools/getMeta');
const catalogUIFlags = useMapGetter('captainToolCatalog/getUIFlags');
const providers = useMapGetter('captainToolCatalog/getProviders');
const capacity = useMapGetter('captainToolCatalog/getCapacity');

const activeView = computed(() =>
  canManageCatalog.value && route.query.view === 'browse'
    ? 'browse'
    : 'installed'
);
const isFetching = computed(
  () =>
    customToolsUIFlags.value.fetchingList ||
    (canManageCatalog.value && catalogUIFlags.value.fetchingCatalog)
);
const showSoftLimitWarning = computed(
  () =>
    !catalogEnabled.value &&
    !isV2.value &&
    customToolsMeta.value.totalCount > SOFT_LIMIT
);
const catalogGroups = computed(() =>
  groupCatalogTools(customTools.value, providers.value)
);
const customGroups = computed(() => groupCustomTools(customTools.value));
const isInstalledEmpty = computed(
  () => activeView.value === 'installed' && !customTools.value.length
);
const pageButtonLabel = computed(() => {
  if (activeView.value === 'browse') return '';
  return catalogEnabled.value
    ? t('CAPTAIN.CUSTOM_TOOLS.CATALOG.BUILD_CUSTOM_TOOL')
    : t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW');
});
const tabs = computed(() => [
  {
    key: 'installed',
    label: t('CAPTAIN.CUSTOM_TOOLS.CATALOG.INSTALLED'),
  },
  {
    key: 'browse',
    label: t('CAPTAIN.CUSTOM_TOOLS.CATALOG.BROWSE'),
  },
]);
const plannedProviders = computed(() => [
  {
    key: 'jira',
    name: 'Jira',
    description: t('CAPTAIN.CUSTOM_TOOLS.CATALOG.JIRA_DESCRIPTION'),
    availability: 'planned',
  },
  {
    key: 'asana',
    name: 'Asana',
    description: t('CAPTAIN.CUSTOM_TOOLS.CATALOG.ASANA_DESCRIPTION'),
    availability: 'planned',
  },
]);
const providerCards = computed(() => [
  ...providers.value,
  ...plannedProviders.value,
]);

const createDialogRef = ref(null);
const deleteDialogRef = ref(null);
const selectedTool = ref(null);
const dialogType = ref('');

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
  const tool = customTools.value.find(candidate => candidate.id === id);
  if (action === 'edit') {
    handleEdit(tool);
  } else if (action === 'delete') {
    handleDelete(tool);
  }
};

const handleDialogClose = () => {
  dialogType.value = '';
  selectedTool.value = null;
};

const onDeleteSuccess = () => {
  selectedTool.value = null;
  if (customTools.value.length === 1 && customToolsMeta.value.page > 1) {
    onPageChange(customToolsMeta.value.page - 1);
  } else {
    fetchCustomTools(customToolsMeta.value.page);
  }
};

const setActiveView = view => {
  if (view === 'browse') {
    useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.CATALOG_VIEWED, {
      source: 'tools_tab',
    });
  }
  router.replace({
    query: {
      ...route.query,
      view: view === 'browse' ? 'browse' : undefined,
    },
  });
};

const openProvider = providerKey => {
  useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.PROVIDER_VIEWED, {
    provider: providerKey,
    source: activeView.value,
  });
  router.push({
    name: 'captain_tools_catalog_provider',
    params: { ...route.params, providerKey },
  });
};

onMounted(() => {
  if (!shouldShowPaywall(pageFeatureFlag.value)) {
    fetchCustomTools();
    if (canManageCatalog.value) {
      store.dispatch('captainToolCatalog/get');
      if (activeView.value === 'browse') {
        useTrack(CAPTAIN_TOOL_CATALOG_EVENTS.CATALOG_VIEWED, {
          source: 'direct',
        });
      }
    }
  }
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.CUSTOM_TOOLS.HEADER')"
    :button-label="pageButtonLabel"
    :button-policy="['administrator']"
    :feature-flag="pageFeatureFlag"
    :total-count="customToolsMeta.totalCount"
    :current-page="customToolsMeta.page"
    :show-pagination-footer="
      !catalogEnabled && !isFetching && !!customTools.length
    "
    :is-fetching="isFetching"
    :is-empty="isInstalledEmpty"
    :show-know-more="false"
    @update:current-page="onPageChange"
    @click="openCreateDialog"
  >
    <template #paywall>
      <CaptainPaywall feature-prefix="CAPTAIN.CUSTOM_TOOLS" />
    </template>

    <template #controls>
      <div
        v-if="canManageCatalog"
        role="tablist"
        :aria-label="$t('CAPTAIN.CUSTOM_TOOLS.CATALOG.NAVIGATION')"
        class="mb-6 flex w-fit rounded-lg bg-n-alpha-1 p-1"
      >
        <button
          v-for="tab in tabs"
          :key="tab.key"
          type="button"
          role="tab"
          :aria-selected="activeView === tab.key"
          class="rounded-md px-4 py-2 text-sm transition-colors"
          :class="
            activeView === tab.key
              ? 'bg-n-solid-active text-n-blue-11 shadow-sm'
              : 'text-n-slate-10 hover:text-n-slate-12'
          "
          @click="setActiveView(tab.key)"
        >
          {{ tab.label }}
        </button>
      </div>
    </template>

    <template #emptyState>
      <CustomToolsPageEmptyState @click="openCreateDialog" />
    </template>

    <template #body>
      <div v-if="activeView === 'installed'" class="flex flex-col gap-6 pb-8">
        <div
          v-if="showSoftLimitWarning"
          class="flex items-center gap-2 rounded-lg bg-n-amber-2 px-4 py-3 text-sm text-n-amber-11"
        >
          <span class="i-lucide-triangle-alert size-4 shrink-0" />
          {{ $t('CAPTAIN.CUSTOM_TOOLS.SOFT_LIMIT_WARNING') }}
        </div>

        <template v-if="catalogEnabled">
          <InstalledGroup
            v-for="group in catalogGroups"
            :key="group.key"
            :group="group"
            :can-manage="canManageCatalog"
            @open="openProvider"
          />

          <section
            v-for="group in customGroups"
            :key="group.key"
            class="flex flex-col gap-4"
          >
            <div>
              <h2 class="font-medium text-n-slate-12">{{ group.name }}</h2>
              <p class="text-sm text-n-slate-10">
                {{
                  $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.TOOL_COUNT', {
                    count: group.tools.length,
                  })
                }}
              </p>
            </div>
            <CustomToolCard
              v-for="tool in group.tools"
              :id="tool.id"
              :key="tool.id"
              :title="tool.title"
              :description="tool.description"
              :endpoint-url="tool.endpoint_url"
              :http-method="tool.http_method"
              :auth-type="tool.auth_type"
              :param-schema="tool.param_schema"
              :enabled="tool.enabled"
              :created-at="tool.created_at"
              :updated-at="tool.updated_at"
              @action="handleAction"
            />
          </section>
        </template>

        <template v-else>
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
            :created-at="tool.created_at"
            :updated-at="tool.updated_at"
            @action="handleAction"
          />
        </template>
      </div>

      <div v-else class="flex flex-col gap-5 pb-10">
        <div
          class="flex flex-col gap-3 rounded-xl border border-n-weak bg-n-alpha-1 p-4 sm:flex-row sm:items-center sm:justify-between"
        >
          <div>
            <h2 class="font-medium text-n-slate-12">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.BROWSE_TITLE') }}
            </h2>
            <p class="mt-1 text-sm text-n-slate-10">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.BROWSE_DESCRIPTION') }}
            </p>
          </div>
          <div class="text-sm sm:text-right">
            <p class="text-n-slate-10">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CAPACITY') }}
            </p>
            <p class="font-medium text-n-slate-12">
              {{
                $t('CAPTAIN.CUSTOM_TOOLS.CATALOG.CAPACITY_SUMMARY', {
                  used: capacity.used,
                  limit: capacity.limit,
                })
              }}
            </p>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
          <ProviderCard
            v-for="provider in providerCards"
            :key="provider.key"
            :provider="provider"
            @open="openProvider"
          />
        </div>
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
</template>
