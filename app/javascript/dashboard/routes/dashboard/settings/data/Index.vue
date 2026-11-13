<script setup>
import {
  computed,
  onActivated,
  onBeforeUnmount,
  onDeactivated,
  ref,
  watch,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import DataExportsAPI from 'dashboard/api/dataExports';
import NewImportDialog from './NewImportDialog.vue';
import NewExportDialog from './NewExportDialog.vue';
import { consumeExportDraft } from './exportDraft';
import DataOperationList from './components/DataOperationList.vue';
import { POLL_INTERVAL_MS, isActiveImport } from './importStatus';

const { t } = useI18n();
const getters = useStoreGetters();
const router = useRouter();
const route = useRoute();

const dataImports = ref([]);
const recentExports = ref([]);
const olderExports = ref([]);
const dataExports = computed(() =>
  recentExports.value.concat(olderExports.value)
);
const hasMoreExports = ref(false);
const loadingOlderExports = ref(false);
const canCreateImport = ref(null);
const integrationEnabled = ref(false);
const initialSource = ref('');
const showExportDialog = ref(false);
const exportSelection = ref({});
const shortcutError = ref('');
const loadError = ref('');
const isLoading = ref(true);
const isRefreshing = ref(false);
const isPolling = ref(false);
const showImportDrawer = ref(false);
const activeTab = computed(() =>
  route.query.tab === 'export' ? 'export' : 'import'
);
const isExport = computed(() => activeTab.value === 'export');
const visibleItems = computed(() =>
  isExport.value ? dataExports.value : dataImports.value
);
let pollTimer;
let isPageActive = false;
let requestVersion = 0;

const accountId = getters.getCurrentAccountId;

const tabs = computed(() => [
  { key: 'import', label: t('DATA_IMPORTS.TABS.IMPORT') },
  { key: 'export', label: t('DATA_IMPORTS.TABS.EXPORT') },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.key === activeTab.value)
);

const hasActiveOperation = computed(
  () =>
    canCreateImport.value === false ||
    dataImports.value.some(isActiveImport) ||
    recentExports.value.some(item => isActiveImport(item) && !item.stalled)
);

const updateRecentExports = ({ payload, has_more: hasMore }) => {
  const boundary = recentExports.value.findIndex(
    item => item.id === payload.at(-1)?.id
  );
  if (
    hasMore &&
    boundary >= 0 &&
    (olderExports.value.length || loadingOlderExports.value)
  ) {
    // Keep rows displaced from the first page while someone is browsing older exports.
    olderExports.value = recentExports.value
      .slice(boundary + 1)
      .concat(olderExports.value);
  } else {
    olderExports.value = [];
    hasMoreExports.value = hasMore;
  }
  recentExports.value = payload;
};

const loadOlderExports = async () => {
  if (loadingOlderExports.value || !hasMoreExports.value) return;
  const beforeId = dataExports.value.at(-1).id;
  const version = requestVersion;
  loadingOlderExports.value = true;
  try {
    const { data } = await DataExportsAPI.get({ beforeId });
    if (version !== requestVersion || beforeId !== dataExports.value.at(-1)?.id)
      return;
    olderExports.value = olderExports.value.concat(data.payload);
    hasMoreExports.value = data.has_more;
  } catch {
    if (version === requestVersion)
      useAlert(t('DATA_EXPORTS.LOAD_OLDER_ERROR'));
  } finally {
    loadingOlderExports.value = false;
  }
};

const fetchHistory = async () => {
  const version = requestVersion;
  const [response, exportsResponse] = await Promise.all([
    DataImportsAPI.get(),
    DataExportsAPI.get(),
  ]);
  if (version !== requestVersion) return;
  dataImports.value = response.data.payload || [];
  canCreateImport.value = response.data.can_create_import;
  integrationEnabled.value = response.data.integration_imports_enabled;
  updateRecentExports(exportsResponse.data);
  loadError.value = '';
};

const stopPolling = () => {
  if (!pollTimer) return;

  window.clearInterval(pollTimer);
  pollTimer = null;
};

const refreshInBackground = async () => {
  if (
    !isPageActive ||
    isPolling.value ||
    !hasActiveOperation.value ||
    document.hidden
  ) {
    return;
  }

  isPolling.value = true;
  try {
    await fetchHistory();
  } catch {
    loadError.value = t('DATA_IMPORTS.ALERTS.LOAD_FAILED');
  } finally {
    isPolling.value = false;
    if (!hasActiveOperation.value) stopPolling();
  }
};

const startPolling = () => {
  stopPolling();
  if (!isPageActive || !hasActiveOperation.value) return;

  pollTimer = window.setInterval(refreshInBackground, POLL_INTERVAL_MS);
};

const refresh = async ({ showLoader = true } = {}) => {
  if (showLoader) isLoading.value = true;
  else isRefreshing.value = true;

  try {
    await fetchHistory();
  } catch {
    loadError.value = t('DATA_IMPORTS.ALERTS.LOAD_FAILED');
  } finally {
    isLoading.value = false;
    isRefreshing.value = false;
    if (isPageActive) {
      if (hasActiveOperation.value && !pollTimer) startPolling();
      if (!hasActiveOperation.value) stopPolling();
    }
  }
};

const openImport = dataImportId => {
  showImportDrawer.value = false;
  router.push({
    name: 'settings_data_import_show',
    params: { accountId: accountId.value, dataImportId },
  });
};

const openImportDrawer = () => {
  initialSource.value = '';
  if (canCreateImport.value) showImportDrawer.value = true;
  else if (canCreateImport.value === false)
    useAlert(t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT'));
};

const openExport = dataExportId => {
  showExportDialog.value = false;
  router.push({
    name: 'settings_data_export_show',
    params: { accountId: accountId.value, dataExportId },
  });
};
const newExport = () => {
  exportSelection.value = {};
  shortcutError.value = '';
  showExportDialog.value = true;
};
const consumeAction = async () => {
  if (!route.query.action) return;
  if (route.query.action === 'import') {
    initialSource.value = 'csv';
    if (canCreateImport.value) showImportDrawer.value = true;
    else if (canCreateImport.value === false)
      useAlert(t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT'));
  } else if (route.query.action === 'export') {
    try {
      exportSelection.value = consumeExportDraft(
        accountId.value,
        route.query.draft
      );
      shortcutError.value = '';
      showExportDialog.value = true;
    } catch {
      shortcutError.value = t('DATA_EXPORTS.DRAFT_UNAVAILABLE');
    }
  }
  await router.replace({ query: { tab: activeTab.value } });
};

const onTabChanged = tab => {
  router.replace({ query: { tab: tab.key } });
};

const handleVisibilityChange = () => {
  if (isPageActive && !document.hidden && hasActiveOperation.value) {
    refreshInBackground();
  }
};

onActivated(async () => {
  isPageActive = true;
  await refresh();
  if (!isPageActive) return;

  await consumeAction();
  startPolling();
  document.addEventListener('visibilitychange', handleVisibilityChange);
});

watch(
  () => route.query.action,
  action => {
    if (action && isPageActive) consumeAction();
  }
);

onDeactivated(() => {
  requestVersion += 1;
  isPageActive = false;
  showImportDrawer.value = false;
  showExportDialog.value = false;
  stopPolling();
  document.removeEventListener('visibilitychange', handleVisibilityChange);
});

onBeforeUnmount(() => {
  requestVersion += 1;
  isPageActive = false;
  stopPolling();
  document.removeEventListener('visibilitychange', handleVisibilityChange);
});
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('DATA_IMPORTS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('DATA_IMPORTS.HEADER')"
        :description="$t('DATA_IMPORTS.DESCRIPTION')"
      >
        <template #tabs>
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTabIndex"
            @tab-changed="onTabChanged"
          />
        </template>
        <template v-if="dataImports.length || dataExports.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{
              activeTab === 'import'
                ? $t('DATA_IMPORTS.TABLE.COUNT', { count: dataImports.length })
                : $t('DATA_EXPORTS.TABLE.COUNT', { count: dataExports.length })
            }}
          </span>
        </template>
        <template #actions>
          <span
            v-if="hasActiveOperation"
            class="hidden items-center gap-1.5 text-body-main text-n-slate-11 sm:inline-flex"
          >
            <span class="size-2 rounded-full bg-n-teal-9 animate-pulse" />
            {{
              $t('DATA_IMPORTS.MONITOR.LIVE', {
                seconds: POLL_INTERVAL_MS / 1000,
              })
            }}
          </span>
          <Button
            ghost
            slate
            size="sm"
            icon="i-lucide-refresh-cw"
            :is-loading="isRefreshing"
            :aria-label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
            :title="$t('DATA_IMPORTS.MONITOR.REFRESH')"
            @click="refresh({ showLoader: false })"
          />
          <Button
            v-if="activeTab === 'import'"
            size="sm"
            icon="i-lucide-plus"
            :label="$t('DATA_IMPORTS.TABLE.NEW_IMPORT')"
            :disabled="isLoading || canCreateImport === null"
            @click="openImportDrawer"
          />
          <Button
            v-if="activeTab === 'export'"
            size="sm"
            icon="i-lucide-plus"
            :label="$t('DATA_EXPORTS.NEW')"
            @click="newExport"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <p
        v-if="loadError"
        role="alert"
        class="mb-4 text-body-main text-n-ruby-11"
      >
        {{ loadError }}
      </p>
      <p
        v-if="shortcutError"
        role="alert"
        class="mb-4 text-body-main text-n-ruby-11"
      >
        {{ shortcutError }}
      </p>
      <div
        v-if="!visibleItems.length"
        class="flex min-h-80 flex-col items-center justify-center gap-4 rounded-xl border border-n-weak bg-n-solid-1 px-6 py-16 text-center"
      >
        <span
          class="flex size-12 items-center justify-center rounded-xl border border-n-weak bg-n-alpha-1"
        >
          <Icon
            :icon="isExport ? 'i-lucide-file-output' : 'i-lucide-file-input'"
            class="size-5 text-n-slate-11"
          />
        </span>
        <div class="flex flex-col gap-1">
          <h3 class="text-heading-2 text-n-slate-12">
            {{
              isExport
                ? $t('DATA_EXPORTS.EMPTY')
                : $t('DATA_IMPORTS.TABLE.EMPTY')
            }}
          </h3>
          <p class="max-w-sm text-body-main text-n-slate-11">
            {{
              isExport
                ? $t('DATA_EXPORTS.EMPTY_DESCRIPTION')
                : $t('DATA_IMPORTS.TABLE.EMPTY_DESCRIPTION')
            }}
          </p>
        </div>
        <Button
          size="sm"
          icon="i-lucide-plus"
          :label="
            isExport
              ? $t('DATA_EXPORTS.NEW')
              : $t('DATA_IMPORTS.TABLE.NEW_IMPORT')
          "
          :disabled="!isExport && (isLoading || canCreateImport === null)"
          @click="isExport ? newExport() : openImportDrawer()"
        />
      </div>

      <DataOperationList
        v-else
        :items="visibleItems"
        :type="activeTab"
        @open="isExport ? openExport($event) : openImport($event)"
      />
      <div v-if="isExport && hasMoreExports" class="mt-4 flex justify-center">
        <Button
          slate
          outline
          size="sm"
          :label="$t('DATA_EXPORTS.LOAD_OLDER')"
          :is-loading="loadingOlderExports"
          @click="loadOlderExports"
        />
      </div>
    </template>
  </SettingsLayout>

  <NewImportDialog
    :show="showImportDrawer"
    :has-active-import="!canCreateImport"
    :integration-enabled="integrationEnabled"
    :initial-source="initialSource"
    @close="showImportDrawer = false"
    @created="openImport"
  />
  <NewExportDialog
    :show="showExportDialog"
    :selection="exportSelection"
    @close="showExportDialog = false"
    @created="openExport"
  />
</template>
