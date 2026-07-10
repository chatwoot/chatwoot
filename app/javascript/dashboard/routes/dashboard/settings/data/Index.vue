<script setup>
import {
  computed,
  onActivated,
  onBeforeUnmount,
  onDeactivated,
  ref,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStoreGetters } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import NewImportDrawer from './NewImportDrawer.vue';
import { IMPORT_SOURCES, importSourceFor } from './importSources';
import {
  POLL_INTERVAL_MS,
  formatStatus,
  importedCount,
  isActiveImport,
} from './importStatus';

const { t } = useI18n();
const getters = useStoreGetters();
const router = useRouter();

const dataImports = ref([]);
const isLoading = ref(true);
const isRefreshing = ref(false);
const isPolling = ref(false);
const showImportDrawer = ref(false);
const activeTab = ref('import');
let pollTimer;

const accountId = getters.getCurrentAccountId;

const tabs = computed(() => [
  { key: 'import', label: t('DATA_IMPORTS.TABS.IMPORT') },
  { key: 'export', label: t('DATA_IMPORTS.TABS.EXPORT') },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.key === activeTab.value)
);

const hasActiveImport = computed(() => dataImports.value.some(isActiveImport));

const dataImportRoute = dataImport => ({
  name: 'settings_data_import_show',
  params: { accountId: accountId.value, dataImportId: dataImport.id },
});

const formatDate = value => {
  if (!value) return '-';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
};

const importTypesFor = dataImport =>
  dataImport.import_types?.length
    ? dataImport.import_types
    : [dataImport.data_type];

const importTypeLabel = dataImport =>
  importTypesFor(dataImport)
    .map(type => {
      if (type === 'contacts') return t('DATA_IMPORTS.TYPES.CONTACTS');
      if (type === 'conversations') {
        return t('DATA_IMPORTS.TYPES.CONVERSATIONS');
      }
      return type;
    })
    .join(', ');

const fetchImports = async () => {
  const response = await DataImportsAPI.get();
  dataImports.value = response.data.payload || [];
};

const stopPolling = () => {
  if (!pollTimer) return;

  window.clearInterval(pollTimer);
  pollTimer = null;
};

const refreshImportsInBackground = async () => {
  if (isPolling.value || !hasActiveImport.value || document.hidden) return;

  isPolling.value = true;
  try {
    await fetchImports();
  } finally {
    isPolling.value = false;
    if (!hasActiveImport.value) stopPolling();
  }
};

const startPolling = () => {
  stopPolling();
  if (!hasActiveImport.value) return;

  pollTimer = window.setInterval(refreshImportsInBackground, POLL_INTERVAL_MS);
};

const refresh = async ({ showLoader = true } = {}) => {
  if (showLoader) isLoading.value = true;
  else isRefreshing.value = true;

  try {
    await fetchImports();
  } finally {
    isLoading.value = false;
    isRefreshing.value = false;
    if (hasActiveImport.value && !pollTimer) startPolling();
    if (!hasActiveImport.value) stopPolling();
  }
};

const openImport = dataImport => {
  router.push(dataImportRoute(dataImport));
};

const openImportDrawer = () => {
  if (!hasActiveImport.value) showImportDrawer.value = true;
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
};

const handleVisibilityChange = () => {
  if (!document.hidden && hasActiveImport.value) refreshImportsInBackground();
};

onActivated(async () => {
  await refresh();
  startPolling();
  document.addEventListener('visibilitychange', handleVisibilityChange);
});

onDeactivated(() => {
  stopPolling();
  document.removeEventListener('visibilitychange', handleVisibilityChange);
});

onBeforeUnmount(() => {
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
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div
        v-if="activeTab === 'export'"
        class="rounded-lg bg-n-card outline outline-1 outline-n-container p-6"
      >
        <h2 class="text-heading-3 text-n-slate-12">
          {{ $t('DATA_IMPORTS.EXPORT.TITLE') }}
        </h2>
        <p class="mt-1 text-body-main text-n-slate-11">
          {{ $t('DATA_IMPORTS.EXPORT.DESCRIPTION') }}
        </p>
      </div>

      <section
        v-else
        class="overflow-hidden rounded-lg bg-n-card outline outline-1 outline-n-container"
      >
        <div
          class="flex items-center justify-between gap-3 border-b border-n-weak px-4 py-3"
        >
          <div class="flex min-w-0 items-center gap-3">
            <h2 class="text-heading-3 text-n-slate-12">
              {{ $t('DATA_IMPORTS.TABLE.TITLE') }}
            </h2>
            <span
              v-if="hasActiveImport"
              class="inline-flex items-center gap-1.5 text-xs text-n-slate-11"
            >
              <span class="size-2 rounded-full bg-n-teal-9 animate-pulse" />
              {{
                $t('DATA_IMPORTS.MONITOR.LIVE', {
                  seconds: POLL_INTERVAL_MS / 1000,
                })
              }}
            </span>
          </div>
          <div class="flex items-center gap-2">
            <Button
              ghost
              slate
              icon="i-lucide-refresh-cw"
              :is-loading="isRefreshing"
              :aria-label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
              :title="$t('DATA_IMPORTS.MONITOR.REFRESH')"
              @click="refresh({ showLoader: false })"
            />
            <Button
              v-if="dataImports.length"
              icon="i-lucide-download"
              :label="$t('DATA_IMPORTS.TABLE.NEW_IMPORT')"
              :disabled="hasActiveImport"
              :title="
                hasActiveImport
                  ? $t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT')
                  : undefined
              "
              @click="openImportDrawer"
            />
          </div>
        </div>

        <div
          v-if="!dataImports.length"
          class="flex flex-col items-center gap-4 px-6 py-12 text-center"
        >
          <img
            :src="IMPORT_SOURCES[0].icon"
            alt=""
            class="size-12 object-contain"
          />
          <div>
            <h3 class="text-heading-3 text-n-slate-12">
              {{ $t('DATA_IMPORTS.TABLE.EMPTY') }}
            </h3>
            <p class="mt-1 text-sm text-n-slate-11">
              {{ $t('DATA_IMPORTS.TABLE.EMPTY_DESCRIPTION') }}
            </p>
          </div>
          <Button
            icon="i-lucide-download"
            :label="$t('DATA_IMPORTS.TABLE.NEW_IMPORT')"
            @click="openImportDrawer"
          />
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead class="bg-n-alpha-1 text-n-slate-11">
              <tr>
                <th class="px-4 py-3 text-left font-medium">
                  {{ $t('DATA_IMPORTS.TABLE.NAME') }}
                </th>
                <th class="px-4 py-3 text-left font-medium">
                  {{ $t('DATA_IMPORTS.TABLE.TYPE') }}
                </th>
                <th class="px-4 py-3 text-left font-medium">
                  {{ $t('DATA_IMPORTS.TABLE.STATUS') }}
                </th>
                <th class="px-4 py-3 text-left font-medium">
                  {{ $t('DATA_IMPORTS.TABLE.IMPORTED') }}
                </th>
                <th class="px-4 py-3 text-left font-medium">
                  {{ $t('DATA_IMPORTS.TABLE.CREATED') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="dataImport in dataImports"
                :key="dataImport.id"
                class="cursor-pointer border-t border-n-weak text-n-slate-12 hover:bg-n-alpha-1 focus-within:bg-n-alpha-1"
                tabindex="0"
                role="link"
                @click="openImport(dataImport)"
                @keydown.enter="openImport(dataImport)"
                @keydown.space.prevent="openImport(dataImport)"
              >
                <td class="px-4 py-3">
                  <router-link
                    :to="dataImportRoute(dataImport)"
                    class="flex items-center gap-3 font-medium text-n-blue-11 hover:underline"
                    @click.stop
                  >
                    <img
                      v-if="importSourceFor(dataImport).icon"
                      v-tooltip.top="importSourceFor(dataImport).label"
                      :src="importSourceFor(dataImport).icon"
                      alt=""
                      class="size-7 object-contain"
                    />
                    <Icon
                      v-else
                      v-tooltip.top="importSourceFor(dataImport).label"
                      :icon="importSourceFor(dataImport).iconClass"
                      class="size-7 text-n-slate-10"
                    />
                    <span>
                      {{ dataImport.name || $t('DATA_IMPORTS.TABLE.UNNAMED') }}
                    </span>
                  </router-link>
                </td>
                <td class="px-4 py-3">{{ importTypeLabel(dataImport) }}</td>
                <td class="px-4 py-3 capitalize">
                  {{ formatStatus(dataImport.status) }}
                </td>
                <td class="px-4 py-3">{{ importedCount(dataImport) }}</td>
                <td class="px-4 py-3">
                  {{ formatDate(dataImport.created_at) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
  </SettingsLayout>

  <NewImportDrawer
    :show="showImportDrawer"
    :has-active-import="hasActiveImport"
    @close="showImportDrawer = false"
    @created="onImportCreated"
  />
</template>
