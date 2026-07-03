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
import { useAlert } from 'dashboard/composables';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useStoreGetters } from 'dashboard/composables/store';

import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import IntegrationsAPI from 'dashboard/api/integrations';
import {
  POLL_INTERVAL_MS,
  formatStatus,
  importStageKey,
  importedCount,
  isAbandonableImport,
  isActiveImport,
  statValue,
} from './importStatus';

const { t } = useI18n();
const getters = useStoreGetters();
const router = useRouter();

const dataImports = ref([]);
const intercomHook = ref(null);
const isLoading = ref(true);
const isRefreshing = ref(false);
const isPolling = ref(false);
const isStartingImport = ref(false);
const activeTab = ref('import');
const importName = ref(t('DATA_IMPORTS.DEFAULT_IMPORT_NAME'));
const selectedImportTypes = ref(['contacts', 'conversations']);
const lastUpdatedAt = ref(null);
let pollTimer;

const accountId = getters.getCurrentAccountId;

const tabs = computed(() => [
  { key: 'import', label: t('DATA_IMPORTS.TABS.IMPORT') },
  { key: 'export', label: t('DATA_IMPORTS.TABS.EXPORT') },
]);

const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.key === activeTab.value)
);

const activeImports = computed(() => dataImports.value.filter(isActiveImport));

const hasActiveImport = computed(() => activeImports.value.length > 0);

const monitorImport = computed(
  () => activeImports.value[0] || dataImports.value[0] || null
);

const intercomConnected = computed(() => !!intercomHook.value?.id);

const intercomSettingsRoute = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/intercom`)
);

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

const formatTime = value => {
  if (!value) return '-';
  return new Intl.DateTimeFormat(undefined, {
    hour: 'numeric',
    minute: '2-digit',
    second: '2-digit',
  }).format(value);
};

const lastUpdatedLabel = computed(() =>
  lastUpdatedAt.value
    ? t('DATA_IMPORTS.MONITOR.LAST_UPDATED', {
        time: formatTime(lastUpdatedAt.value),
      })
    : t('DATA_IMPORTS.MONITOR.WAITING')
);

const stageLabels = computed(() => ({
  unknown: t('DATA_IMPORTS.MONITOR.STAGES.unknown'),
  queued: t('DATA_IMPORTS.MONITOR.STAGES.queued'),
  preparing: t('DATA_IMPORTS.MONITOR.STAGES.preparing'),
  contacts: t('DATA_IMPORTS.MONITOR.STAGES.contacts'),
  conversations: t('DATA_IMPORTS.MONITOR.STAGES.conversations'),
  finalizing: t('DATA_IMPORTS.MONITOR.STAGES.finalizing'),
  completed: t('DATA_IMPORTS.MONITOR.STAGES.completed'),
  completed_with_errors: t('DATA_IMPORTS.MONITOR.STAGES.completed_with_errors'),
  failed: t('DATA_IMPORTS.MONITOR.STAGES.failed'),
  abandoned: t('DATA_IMPORTS.MONITOR.STAGES.abandoned'),
}));

const monitorTitle = computed(() => {
  if (!monitorImport.value) return t('DATA_IMPORTS.MONITOR.NO_IMPORTS');
  return (
    stageLabels.value[importStageKey(monitorImport.value)] ||
    stageLabels.value.unknown
  );
});

const monitorSubtitle = computed(() => {
  if (isPolling.value) return t('DATA_IMPORTS.MONITOR.REFRESHING');
  if (hasActiveImport.value) {
    return [
      t('DATA_IMPORTS.MONITOR.LIVE', { seconds: POLL_INTERVAL_MS / 1000 }),
      lastUpdatedLabel.value,
    ].join(' - ');
  }
  return [
    t('DATA_IMPORTS.MONITOR.NO_ACTIVE_IMPORTS'),
    lastUpdatedLabel.value,
  ].join(' - ');
});

const monitorStats = computed(() => [
  {
    label: t('DATA_IMPORTS.DETAIL.CONTACTS_IMPORTED'),
    value: statValue(monitorImport.value, 'contacts', 'imported'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.CONVERSATIONS_IMPORTED'),
    value: statValue(monitorImport.value, 'conversations', 'imported'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.MESSAGES_IMPORTED'),
    value: statValue(monitorImport.value, 'messages', 'imported'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.ERRORS'),
    value: monitorImport.value?.import_errors_count || 0,
  },
]);

const fetchImports = async () => {
  const response = await DataImportsAPI.get();
  dataImports.value = response.data.payload || [];
  lastUpdatedAt.value = new Date();
};

const fetchIntercomConnection = async () => {
  const response = await IntegrationsAPI.getIntercom();
  intercomHook.value = response.data;
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

const startImport = async () => {
  isStartingImport.value = true;
  try {
    const response = await DataImportsAPI.create({
      import_types: selectedImportTypes.value,
      name: importName.value.trim() || t('DATA_IMPORTS.DEFAULT_IMPORT_NAME'),
    });
    useAlert(t('DATA_IMPORTS.ALERTS.IMPORT_STARTED'));
    await fetchImports();
    router.push({
      name: 'settings_data_import_show',
      params: {
        accountId: accountId.value,
        dataImportId: response.data.id,
      },
    });
  } catch (error) {
    useAlert(
      error?.response?.data?.message || t('DATA_IMPORTS.ALERTS.IMPORT_FAILED')
    );
  } finally {
    isStartingImport.value = false;
  }
};

const abandonImport = async id => {
  await DataImportsAPI.abandon(id);
  await fetchImports();
  if (!hasActiveImport.value) stopPolling();
};

const openImport = dataImport => {
  router.push(dataImportRoute(dataImport));
};

const toggleImportType = type => {
  if (selectedImportTypes.value.includes(type)) {
    selectedImportTypes.value = selectedImportTypes.value.filter(
      item => item !== type
    );
    return;
  }
  selectedImportTypes.value = [...selectedImportTypes.value, type];
};

const onTabChanged = tab => {
  activeTab.value = tab.key;
};

const startPolling = () => {
  stopPolling();
  if (!hasActiveImport.value) return;

  pollTimer = window.setInterval(() => {
    refreshImportsInBackground();
  }, POLL_INTERVAL_MS);
};

const refresh = async ({ showLoader = true, manual = false } = {}) => {
  if (showLoader) {
    isLoading.value = true;
  } else if (manual) {
    isRefreshing.value = true;
  }

  try {
    await Promise.all([fetchImports(), fetchIntercomConnection()]);
  } finally {
    if (showLoader) isLoading.value = false;
    if (manual) isRefreshing.value = false;
    if (hasActiveImport.value && !pollTimer) startPolling();
    if (!hasActiveImport.value) stopPolling();
  }
};

const handleVisibilityChange = () => {
  if (!document.hidden && hasActiveImport.value) {
    refreshImportsInBackground();
  }
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
        <p class="text-body-main text-n-slate-11 mt-1">
          {{ $t('DATA_IMPORTS.EXPORT.DESCRIPTION') }}
        </p>
      </div>

      <div v-else class="flex flex-col gap-4">
        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container p-4 flex flex-col gap-4"
        >
          <div class="flex items-start justify-between gap-4">
            <div>
              <h2 class="text-heading-3 text-n-slate-12">
                {{ $t('DATA_IMPORTS.INTERCOM.TITLE') }}
              </h2>
              <p class="text-body-main text-n-slate-11 mt-1 max-w-3xl">
                {{ $t('DATA_IMPORTS.INTERCOM.DESCRIPTION') }}
              </p>
            </div>
            <router-link v-if="!intercomConnected" :to="intercomSettingsRoute">
              <Button
                :label="$t('DATA_IMPORTS.INTERCOM.CONNECT')"
                icon="i-lucide-plug"
              />
            </router-link>
          </div>

          <div v-if="intercomConnected" class="flex flex-col gap-3">
            <label class="flex flex-col gap-1 max-w-lg">
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('DATA_IMPORTS.INTERCOM.NAME_LABEL') }}
              </span>
              <input
                v-model="importName"
                type="text"
                class="h-10 rounded-lg border border-n-weak bg-n-alpha-1 px-3 text-sm text-n-slate-12 outline-none transition-colors placeholder:text-n-slate-10 focus:border-n-brand"
                :placeholder="$t('DATA_IMPORTS.INTERCOM.NAME_PLACEHOLDER')"
              />
            </label>
            <div class="flex items-center gap-3">
              <label
                class="inline-flex items-center gap-2 text-sm text-n-slate-12"
              >
                <input
                  type="checkbox"
                  class="rounded border-n-strong"
                  :checked="selectedImportTypes.includes('contacts')"
                  @change="toggleImportType('contacts')"
                />
                {{ $t('DATA_IMPORTS.TYPES.CONTACTS') }}
              </label>
              <label
                class="inline-flex items-center gap-2 text-sm text-n-slate-12"
              >
                <input
                  type="checkbox"
                  class="rounded border-n-strong"
                  :checked="selectedImportTypes.includes('conversations')"
                  @change="toggleImportType('conversations')"
                />
                {{ $t('DATA_IMPORTS.TYPES.CONVERSATIONS') }}
              </label>
            </div>
            <div class="flex items-center gap-3">
              <Button
                :label="$t('DATA_IMPORTS.INTERCOM.START_IMPORT')"
                icon="i-lucide-download"
                :is-loading="isStartingImport"
                :disabled="!selectedImportTypes.length || isStartingImport"
                @click="startImport"
              />
              <span class="text-sm text-n-slate-10">
                {{ $t('DATA_IMPORTS.INTERCOM.PLACEHOLDER_NOTE') }}
              </span>
            </div>
          </div>
        </section>

        <section
          v-if="dataImports.length"
          class="rounded-lg bg-n-card outline outline-1 outline-n-container p-4"
        >
          <div
            class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between"
          >
            <div class="flex gap-3">
              <span
                class="mt-1 size-2.5 rounded-full"
                :class="
                  hasActiveImport ? 'bg-n-teal-9 animate-pulse' : 'bg-n-slate-8'
                "
              />
              <div>
                <h2 class="text-heading-3 text-n-slate-12">
                  {{ monitorTitle }}
                </h2>
                <p class="text-sm text-n-slate-11 mt-1">
                  {{ monitorSubtitle }}
                </p>
              </div>
            </div>
            <Button
              ghost
              slate
              sm
              icon="i-lucide-refresh-cw"
              :is-loading="isRefreshing"
              :label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
              @click="refresh({ showLoader: false, manual: true })"
            />
          </div>
          <dl
            v-if="monitorImport"
            class="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4"
          >
            <div v-for="item in monitorStats" :key="item.label">
              <dt class="text-sm text-n-slate-11">
                {{ item.label }}
              </dt>
              <dd class="mt-1 text-heading-3 text-n-slate-12">
                {{ item.value }}
              </dd>
            </div>
          </dl>
        </section>

        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container overflow-hidden"
        >
          <div
            class="px-4 py-3 border-b border-n-weak flex items-center justify-between gap-3"
          >
            <h2 class="text-heading-3 text-n-slate-12">
              {{ $t('DATA_IMPORTS.TABLE.TITLE') }}
            </h2>
            <Button
              v-if="!dataImports.length"
              ghost
              slate
              xs
              icon="i-lucide-refresh-cw"
              :is-loading="isRefreshing"
              :label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
              @click="refresh({ showLoader: false, manual: true })"
            />
          </div>
          <div
            v-if="!dataImports.length"
            class="p-8 text-center text-n-slate-11"
          >
            {{ $t('DATA_IMPORTS.TABLE.EMPTY') }}
          </div>
          <div v-else class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-n-alpha-1 text-n-slate-11">
                <tr>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.TABLE.NAME') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.TABLE.TYPE') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.TABLE.STATUS') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.TABLE.IMPORTED') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.TABLE.CREATED') }}
                  </th>
                  <th class="text-right px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.TABLE.ACTIONS') }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="dataImport in dataImports"
                  :key="dataImport.id"
                  class="border-t border-n-weak text-n-slate-12 cursor-pointer hover:bg-n-alpha-1 focus-within:bg-n-alpha-1"
                  tabindex="0"
                  role="link"
                  @click="openImport(dataImport)"
                  @keydown.enter="openImport(dataImport)"
                  @keydown.space.prevent="openImport(dataImport)"
                >
                  <td class="px-4 py-3">
                    <router-link
                      :to="dataImportRoute(dataImport)"
                      class="font-medium text-n-blue-11 hover:underline"
                      @click.stop
                    >
                      {{ dataImport.name || $t('DATA_IMPORTS.TABLE.UNNAMED') }}
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
                  <td class="px-4 py-3 text-right">
                    <Button
                      v-if="isAbandonableImport(dataImport)"
                      ghost
                      xs
                      ruby
                      :label="$t('DATA_IMPORTS.TABLE.ABANDON')"
                      @click.stop="abandonImport(dataImport.id)"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </template>
  </SettingsLayout>
</template>
