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
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import NewImportDialog from './NewImportDialog.vue';
import DataOperationList from './components/DataOperationList.vue';
import { POLL_INTERVAL_MS, isActiveImport } from './importStatus';

const { t } = useI18n();
const getters = useStoreGetters();
const router = useRouter();
const route = useRoute();

const dataImports = ref([]);
const canCreateImport = ref(null);
const integrationEnabled = ref(false);
const initialSource = ref('');
const loadError = ref('');
const isLoading = ref(true);
const isRefreshing = ref(false);
const isPolling = ref(false);
const showImportDrawer = ref(false);
let pollTimer;
let isPageActive = false;
let requestVersion = 0;

const accountId = getters.getCurrentAccountId;

const hasActiveImport = computed(
  () =>
    canCreateImport.value === false || dataImports.value.some(isActiveImport)
);
const dataImportRoute = dataImport => ({
  name: 'settings_data_import_show',
  params: { accountId: accountId.value, dataImportId: dataImport.id },
});

const fetchImports = async () => {
  const version = requestVersion;
  const response = await DataImportsAPI.get();
  if (version !== requestVersion) return;
  dataImports.value = response.data.payload || [];
  canCreateImport.value = response.data.can_create_import;
  integrationEnabled.value = response.data.integration_imports_enabled;
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
    !hasActiveImport.value ||
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
    if (!hasActiveImport.value) stopPolling();
  }
};

const startPolling = () => {
  stopPolling();
  if (!isPageActive || !hasActiveImport.value) return;

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
      if (hasActiveImport.value && !pollTimer) startPolling();
      if (!hasActiveImport.value) stopPolling();
    }
  }
};

const openImport = dataImportId => {
  router.push(dataImportRoute({ id: dataImportId }));
};

const openImportDrawer = () => {
  if (canCreateImport.value) showImportDrawer.value = true;
  else if (canCreateImport.value === false)
    useAlert(t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT'));
};

const consumeAction = async () => {
  if (route.query.action !== 'import') return;
  initialSource.value = 'csv';
  if (canCreateImport.value) showImportDrawer.value = true;
  else if (canCreateImport.value === false)
    useAlert(t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT'));
  await router.replace({ query: { tab: 'import' } });
};

const onImportCreated = dataImportId => {
  showImportDrawer.value = false;
  router.push({
    name: 'settings_data_import_show',
    params: { accountId: accountId.value, dataImportId },
  });
};

const handleVisibilityChange = () => {
  if (isPageActive && !document.hidden && hasActiveImport.value) {
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
  () => route.query.action,
  action => {
    if (action && isPageActive) consumeAction();
  }
);

onDeactivated(() => {
  requestVersion += 1;
  isPageActive = false;
  showImportDrawer.value = false;
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
        <template v-if="dataImports.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('DATA_IMPORTS.TABLE.COUNT', { count: dataImports.length }) }}
          </span>
        </template>
        <template #actions>
          <span
            v-if="hasActiveImport"
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
            size="sm"
            icon="i-lucide-plus"
            :label="$t('DATA_IMPORTS.TABLE.NEW_IMPORT')"
            :disabled="isLoading || canCreateImport === null"
            @click="openImportDrawer"
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
      <div
        v-if="!dataImports.length"
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
          :disabled="isLoading || canCreateImport === null"
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
</template>
