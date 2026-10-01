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
import ExportsList from './ExportsList.vue';
import { consumeExportDraft } from './exportDraft';
import DataOperationList from './components/DataOperationList.vue';
import { POLL_INTERVAL_MS, isActiveImport } from './importStatus';

const { t } = useI18n();
const getters = useStoreGetters();
const router = useRouter();
const route = useRoute();

const dataImports = ref([]);
const dataExports = ref([]);
const canCreateImport = ref(false);
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
const activeTab = ref(route.query.tab === 'export' ? 'export' : 'import');
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

const hasActiveImport = computed(() => dataImports.value.some(isActiveImport));
const hasActiveOperation = computed(
  () => hasActiveImport.value || dataExports.value.some(isActiveImport)
);

const dataImportRoute = dataImport => ({
  name: 'settings_data_import_show',
  params: { accountId: accountId.value, dataImportId: dataImport.id },
});

const fetchImports = async () => {
  const version = requestVersion;
  const [response, exportsResponse] = await Promise.all([
    DataImportsAPI.get(),
    DataExportsAPI.get(),
  ]);
  if (version !== requestVersion) return;
  dataImports.value = response.data.payload || [];
  canCreateImport.value = response.data.can_create_import;
  integrationEnabled.value = response.data.integration_imports_enabled;
  dataExports.value = exportsResponse.data.payload || [];
  loadError.value = '';
};

const stopPolling = () => {
  if (!pollTimer) return;

  window.clearInterval(pollTimer);
  pollTimer = null;
};

const refreshImportsInBackground = async () => {
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
    await fetchImports();
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

  pollTimer = window.setInterval(refreshImportsInBackground, POLL_INTERVAL_MS);
};

const refresh = async ({ showLoader = true } = {}) => {
  if (showLoader) isLoading.value = true;
  else isRefreshing.value = true;

  try {
    await fetchImports();
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
  router.push(dataImportRoute({ id: dataImportId }));
};

const openImportDrawer = () => {
  if (canCreateImport.value) showImportDrawer.value = true;
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
  activeTab.value = route.query.tab === 'export' ? 'export' : 'import';
  if (!route.query.action) return;
  if (route.query.action === 'import') {
    initialSource.value = 'csv';
    if (canCreateImport.value) showImportDrawer.value = true;
    else useAlert(t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT'));
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

const onImportCreated = dataImportId => {
  showImportDrawer.value = false;
  router.push({
    name: 'settings_data_import_show',
    params: { accountId: accountId.value, dataImportId },
  });
};

const onTabChanged = tab => {
  activeTab.value = tab.key;
  router.replace({ query: { tab: tab.key } });
};

const handleVisibilityChange = () => {
  if (isPageActive && !document.hidden && hasActiveOperation.value) {
    refreshImportsInBackground();
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
  () => route.query.tab,
  tab => {
    if (isPageActive) activeTab.value = tab === 'export' ? 'export' : 'import';
  }
);

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
            :disabled="!canCreateImport"
            :title="
              !canCreateImport
                ? $t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT')
                : undefined
            "
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
      <ExportsList
        v-if="activeTab === 'export'"
        :exports="dataExports"
        @open="openExport"
        @create="newExport"
      />

      <div
        v-else-if="!dataImports.length"
        class="flex min-h-80 flex-col items-center justify-center gap-4 rounded-xl border border-n-weak bg-n-solid-1 px-6 py-16 text-center"
      >
        <span
          class="flex size-12 items-center justify-center rounded-xl border border-n-weak bg-n-alpha-1"
        >
          <Icon icon="i-lucide-file-input" class="size-5 text-n-slate-11" />
        </span>
        <div class="flex flex-col gap-1">
          <h3 class="text-heading-2 text-n-slate-12">
            {{ $t('DATA_IMPORTS.TABLE.EMPTY') }}
          </h3>
          <p class="max-w-sm text-body-main text-n-slate-11">
            {{ $t('DATA_IMPORTS.TABLE.EMPTY_DESCRIPTION') }}
          </p>
        </div>
        <Button
          size="sm"
          icon="i-lucide-plus"
          :label="$t('DATA_IMPORTS.TABLE.NEW_IMPORT')"
          @click="openImportDrawer"
        />
      </div>

      <DataOperationList v-else :items="dataImports" @open="openImport" />
    </template>
  </SettingsLayout>

  <NewImportDialog
    :show="showImportDrawer"
    :has-active-import="!canCreateImport"
    :integration-enabled="integrationEnabled"
    :initial-source="initialSource"
    @close="showImportDrawer = false"
    @created="onImportCreated"
  />
  <NewExportDialog
    :show="showExportDialog"
    :selection="exportSelection"
    @close="showExportDialog = false"
    @created="openExport"
  />
</template>
