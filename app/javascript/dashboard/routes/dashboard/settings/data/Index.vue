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
import NewImportDialog from './NewImportDialog.vue';
import { importSourceFor } from './importSources';
import {
  POLL_INTERVAL_MS,
  formatDate,
  formatStatus,
  importedCount,
  isActiveImport,
  isActiveIntercomImport,
  statusDotClass,
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
let isPageActive = false;

const accountId = getters.getCurrentAccountId;

const tabs = computed(() => [
  { key: 'import', label: t('DATA_IMPORTS.TABS.IMPORT') },
  { key: 'export', label: t('DATA_IMPORTS.TABS.EXPORT') },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.key === activeTab.value)
);

const hasActiveImport = computed(() => dataImports.value.some(isActiveImport));
const hasActiveIntercomImport = computed(() =>
  dataImports.value.some(isActiveIntercomImport)
);

const dataImportRoute = dataImport => ({
  name: 'settings_data_import_show',
  params: { accountId: accountId.value, dataImportId: dataImport.id },
});

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
  } finally {
    isLoading.value = false;
    isRefreshing.value = false;
    if (isPageActive) {
      if (hasActiveImport.value && !pollTimer) startPolling();
      if (!hasActiveImport.value) stopPolling();
    }
  }
};

const openImport = dataImport => {
  router.push(dataImportRoute(dataImport));
};

const openImportDrawer = () => {
  if (!hasActiveIntercomImport.value) showImportDrawer.value = true;
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
  if (isPageActive && !document.hidden && hasActiveImport.value) {
    refreshImportsInBackground();
  }
};

onActivated(async () => {
  isPageActive = true;
  await refresh();
  if (!isPageActive) return;

  startPolling();
  document.addEventListener('visibilitychange', handleVisibilityChange);
});

onDeactivated(() => {
  isPageActive = false;
  stopPolling();
  document.removeEventListener('visibilitychange', handleVisibilityChange);
});

onBeforeUnmount(() => {
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
        <template v-if="activeTab === 'import' && dataImports.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('DATA_IMPORTS.TABLE.COUNT', { count: dataImports.length }) }}
          </span>
        </template>
        <template v-if="activeTab === 'import'" #actions>
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
            :label="$t('DATA_IMPORTS.TABLE.NEW_IMPORT')"
            :disabled="hasActiveIntercomImport"
            :title="
              hasActiveIntercomImport
                ? $t('DATA_IMPORTS.DRAWER.ACTIVE_IMPORT')
                : undefined
            "
            @click="openImportDrawer"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div
        v-if="activeTab === 'export'"
        class="flex min-h-80 flex-col items-center justify-center gap-4 rounded-xl border border-n-weak bg-n-solid-1 px-6 py-16 text-center"
      >
        <span
          class="flex size-12 items-center justify-center rounded-full bg-n-alpha-2"
        >
          <Icon icon="i-lucide-upload" class="size-5 text-n-slate-11" />
        </span>
        <div class="flex flex-col gap-1">
          <h3 class="text-heading-2 text-n-slate-12">
            {{ $t('DATA_IMPORTS.EXPORT.TITLE') }}
          </h3>
          <p class="max-w-sm text-body-main text-n-slate-11">
            {{ $t('DATA_IMPORTS.EXPORT.DESCRIPTION') }}
          </p>
        </div>
        <span
          class="inline-flex items-center gap-1.5 rounded-md bg-n-alpha-2 px-2 py-1 text-label-small text-n-slate-11"
        >
          <Icon icon="i-lucide-clock" class="size-3.5" />
          {{ $t('DATA_IMPORTS.EXPORT.COMING_SOON') }}
        </span>
      </div>

      <div
        v-else-if="!dataImports.length"
        class="flex min-h-80 flex-col items-center justify-center gap-4 rounded-xl border border-n-weak bg-n-solid-1 px-6 py-16 text-center"
      >
        <span
          class="flex size-12 items-center justify-center rounded-full bg-n-alpha-2"
        >
          <Icon icon="i-lucide-database" class="size-5 text-n-slate-11" />
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
          icon="i-lucide-download"
          :label="$t('DATA_IMPORTS.TABLE.NEW_IMPORT')"
          @click="openImportDrawer"
        />
      </div>

      <div v-else class="divide-y divide-n-weak border-t border-n-weak">
        <div
          v-for="dataImport in dataImports"
          :key="dataImport.id"
          class="group flex cursor-pointer items-center justify-between gap-4 py-4"
          role="button"
          tabindex="0"
          @click="openImport(dataImport)"
          @keydown.enter="openImport(dataImport)"
          @keydown.space.prevent="openImport(dataImport)"
        >
          <div class="flex min-w-0 items-center gap-3">
            <img
              v-if="importSourceFor(dataImport).icon"
              v-tooltip.top="importSourceFor(dataImport).label"
              :src="importSourceFor(dataImport).icon"
              alt=""
              class="size-10 justify-center bg-n-alpha-3 rounded-xl shrink-0 object-contain border border-n-strong"
            />
            <span
              v-else
              v-tooltip.top="importSourceFor(dataImport).label"
              class="size-10 justify-center bg-n-alpha-3 rounded-xl ring ring-n-solid-1 border border-n-strong shadow-sm grid place-items-center"
            >
              <Icon
                :icon="importSourceFor(dataImport).iconClass"
                class="size-4"
              />
            </span>
            <div class="flex min-w-0 flex-col gap-1">
              <div class="flex items-center gap-2">
                <span class="truncate text-heading-3 text-n-slate-12">
                  {{ dataImport.name || $t('DATA_IMPORTS.TABLE.UNNAMED') }}
                </span>
                <span class="flex shrink-0 items-center gap-1.5">
                  <span
                    class="size-2 rounded-full"
                    :class="[
                      statusDotClass(dataImport.status),
                      { 'animate-pulse': isActiveImport(dataImport) },
                    ]"
                  />
                  <span
                    class="whitespace-nowrap capitalize text-body-main text-n-slate-11"
                  >
                    {{ formatStatus(dataImport.status) }}
                  </span>
                </span>
              </div>
              <div
                class="flex flex-wrap items-center gap-2 text-body-main text-n-slate-11"
              >
                <span>{{ importTypeLabel(dataImport) }}</span>
                <div class="h-3 w-px rounded-lg bg-n-strong" />
                <span class="tabular-nums">
                  {{
                    $t('DATA_IMPORTS.TABLE.IMPORTED_COUNT', {
                      count: importedCount(dataImport),
                    })
                  }}
                </span>
                <div class="h-3 w-px rounded-lg bg-n-strong" />
                <span>{{ formatDate(dataImport.created_at) }}</span>
              </div>
            </div>
          </div>
          <Button
            v-tooltip.top="$t('DATA_IMPORTS.TABLE.VIEW')"
            icon="i-lucide-eye"
            slate
            sm
            class="shrink-0"
            @click.stop="openImport(dataImport)"
          />
        </div>
      </div>
    </template>
  </SettingsLayout>

  <NewImportDialog
    :show="showImportDrawer"
    :has-active-import="hasActiveIntercomImport"
    @close="showImportDrawer = false"
    @created="onImportCreated"
  />
</template>
