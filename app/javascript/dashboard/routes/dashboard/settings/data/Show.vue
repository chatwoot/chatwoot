<script setup>
import {
  computed,
  onActivated,
  onBeforeUnmount,
  onDeactivated,
  ref,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import {
  POLL_INTERVAL_MS,
  importStageKey,
  importedCount as totalImportedCount,
  isAbandonableImport,
  isActiveImport,
  statValue as importStatValue,
} from './importStatus';

const { t } = useI18n();
const route = useRoute();

const dataImport = ref(null);
const isLoading = ref(true);
const isRefreshing = ref(false);
const isPolling = ref(false);
const isAbandoning = ref(false);
const isDownloadingSkipLogs = ref(false);
const isChangingImportErrorsPage = ref(false);
const isChangingSkipLogsPage = ref(false);
const importErrorsPage = ref(1);
const skipLogsPage = ref(1);
const selectedSkipLogsType = ref('');
const lastUpdatedAt = ref(null);
let pollTimer;

const codeBlockClass =
  'mt-4 max-h-80 overflow-auto rounded-md bg-n-alpha-1 p-3 text-xs text-n-slate-12';

const formatDate = value => {
  if (!value) return '-';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
};

const importTypesFor = value =>
  value?.import_types?.length ? value.import_types : [value?.data_type];

const importTypeLabel = value =>
  importTypesFor(value)
    .filter(Boolean)
    .map(type => {
      if (type === 'contacts') return t('DATA_IMPORTS.TYPES.CONTACTS');
      if (type === 'conversations') {
        return t('DATA_IMPORTS.TYPES.CONVERSATIONS');
      }
      return type;
    })
    .join(', ');

const statValue = (group, key) => importStatValue(dataImport.value, group, key);

const importedCount = computed(() => totalImportedCount(dataImport.value));

const importErrors = computed(() => dataImport.value?.import_errors || []);

const importErrorsPagination = computed(
  () =>
    dataImport.value?.import_errors_pagination || {
      current_page: 1,
      total_pages: 1,
      total_count: dataImport.value?.import_errors_count || 0,
      per_page: 15,
    }
);

const hasImportErrorsPagination = computed(
  () => importErrorsPagination.value.total_pages > 1
);

const canGoToPreviousImportErrorsPage = computed(
  () => importErrorsPagination.value.current_page > 1
);

const canGoToNextImportErrorsPage = computed(
  () =>
    importErrorsPagination.value.current_page <
    importErrorsPagination.value.total_pages
);

const skipLogs = computed(() => dataImport.value?.skip_logs || []);

const skipLogsFilters = computed(
  () =>
    dataImport.value?.skip_logs_filters || {
      selected_source_object_type: '',
      counts_by_type: {},
    }
);

const skipLogTypeOptions = computed(() => {
  const counts = skipLogsFilters.value.counts_by_type || {};
  return [
    {
      value: '',
      label: t('DATA_IMPORTS.DETAIL.ALL_SKIP_LOGS'),
      count: dataImport.value?.skip_logs_count || 0,
    },
    {
      value: 'contact',
      label: t('DATA_IMPORTS.TYPES.CONTACTS'),
      count: counts.contact || 0,
    },
    {
      value: 'conversation',
      label: t('DATA_IMPORTS.TYPES.CONVERSATIONS'),
      count: counts.conversation || 0,
    },
    {
      value: 'message',
      label: t('DATA_IMPORTS.TYPES.MESSAGES'),
      count: counts.message || 0,
    },
  ];
});

const skipLogsPagination = computed(
  () =>
    dataImport.value?.skip_logs_pagination || {
      current_page: 1,
      total_pages: 1,
      total_count: dataImport.value?.skip_logs_count || 0,
      per_page: 15,
    }
);

const hasSkipLogsPagination = computed(
  () => skipLogsPagination.value.total_pages > 1
);

const canGoToPreviousSkipLogsPage = computed(
  () => skipLogsPagination.value.current_page > 1
);

const canGoToNextSkipLogsPage = computed(
  () =>
    skipLogsPagination.value.current_page < skipLogsPagination.value.total_pages
);

const hasActiveImport = computed(() => isActiveImport(dataImport.value));

const canAbandonImport = computed(() => isAbandonableImport(dataImport.value));

const title = computed(
  () => dataImport.value?.name || t('DATA_IMPORTS.TABLE.UNNAMED')
);

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

const monitorTitle = computed(
  () =>
    stageLabels.value[importStageKey(dataImport.value)] ||
    stageLabels.value.unknown
);

const monitorSubtitle = computed(() => {
  if (isPolling.value) return t('DATA_IMPORTS.MONITOR.REFRESHING');
  if (hasActiveImport.value) {
    return [
      t('DATA_IMPORTS.MONITOR.LIVE', { seconds: POLL_INTERVAL_MS / 1000 }),
      lastUpdatedLabel.value,
    ].join(' - ');
  }
  return lastUpdatedLabel.value;
});

const summaryItems = computed(() => [
  {
    label: t('DATA_IMPORTS.DETAIL.STATUS'),
    value: monitorTitle.value,
  },
  {
    label: t('DATA_IMPORTS.DETAIL.IMPORTED'),
    value: importedCount.value,
  },
  {
    label: t('DATA_IMPORTS.DETAIL.ERRORS'),
    value: dataImport.value?.import_errors_count || 0,
  },
  {
    label: t('DATA_IMPORTS.DETAIL.SKIP_LOGS'),
    value: dataImport.value?.skip_logs_count || 0,
  },
  {
    label: t('DATA_IMPORTS.DETAIL.ITEMS'),
    value: dataImport.value?.items_count || 0,
  },
]);

const metadataItems = computed(() => [
  {
    label: t('DATA_IMPORTS.DETAIL.SOURCE'),
    value: dataImport.value?.source_provider || dataImport.value?.data_type,
  },
  {
    label: t('DATA_IMPORTS.DETAIL.IMPORT_TYPES'),
    value: importTypeLabel(dataImport.value),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.CREATED'),
    value: formatDate(dataImport.value?.created_at),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.STARTED'),
    value: formatDate(dataImport.value?.started_at),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.COMPLETED'),
    value: formatDate(dataImport.value?.completed_at),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.INITIATED_BY'),
    value: dataImport.value?.initiated_by?.name || '-',
  },
]);

const statItems = computed(() => [
  {
    label: t('DATA_IMPORTS.DETAIL.CONTACTS_IMPORTED'),
    value: statValue('contacts', 'imported'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.CONTACTS_SKIPPED'),
    value: statValue('contacts', 'skipped'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.CONVERSATIONS_IMPORTED'),
    value: statValue('conversations', 'imported'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.CONVERSATIONS_SKIPPED'),
    value: statValue('conversations', 'skipped'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.MESSAGES_IMPORTED'),
    value: statValue('messages', 'imported'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.MESSAGES_SKIPPED'),
    value: statValue('messages', 'skipped'),
  },
]);

const formattedConfig = computed(() =>
  JSON.stringify(dataImport.value?.config || {}, null, 2)
);

const stopPolling = () => {
  if (!pollTimer) return;

  window.clearInterval(pollTimer);
  pollTimer = null;
};

const fetchImport = async ({
  showLoader = false,
  manual = false,
  requestedImportErrorsPage = importErrorsPage.value,
  requestedSkipLogsPage = skipLogsPage.value,
  requestedSkipLogsType = selectedSkipLogsType.value,
} = {}) => {
  if (showLoader) {
    isLoading.value = true;
  } else if (manual) {
    isRefreshing.value = true;
  }

  try {
    const response = await DataImportsAPI.show(route.params.dataImportId, {
      import_errors_page: requestedImportErrorsPage,
      skip_logs_page: requestedSkipLogsPage,
      skip_logs_type: requestedSkipLogsType || undefined,
    });
    dataImport.value = response.data;
    importErrorsPage.value =
      response.data.import_errors_pagination?.current_page ||
      requestedImportErrorsPage;
    skipLogsPage.value =
      response.data.skip_logs_pagination?.current_page || requestedSkipLogsPage;
    selectedSkipLogsType.value =
      response.data.skip_logs_filters?.selected_source_object_type ||
      requestedSkipLogsType ||
      '';
    lastUpdatedAt.value = new Date();
  } finally {
    if (showLoader) isLoading.value = false;
    if (manual) isRefreshing.value = false;
    if (!hasActiveImport.value) stopPolling();
  }
};

const changeImportErrorsPage = async page => {
  if (
    page < 1 ||
    page > importErrorsPagination.value.total_pages ||
    page === importErrorsPagination.value.current_page ||
    isChangingImportErrorsPage.value
  ) {
    return;
  }

  isChangingImportErrorsPage.value = true;
  try {
    await fetchImport({ requestedImportErrorsPage: page });
  } finally {
    isChangingImportErrorsPage.value = false;
  }
};

const changeSkipLogsType = async type => {
  if (type === selectedSkipLogsType.value || isChangingSkipLogsPage.value) {
    return;
  }

  selectedSkipLogsType.value = type;
  skipLogsPage.value = 1;
  isChangingSkipLogsPage.value = true;
  try {
    await fetchImport({
      requestedSkipLogsPage: 1,
      requestedSkipLogsType: type,
    });
  } finally {
    isChangingSkipLogsPage.value = false;
  }
};

const changeSkipLogsPage = async page => {
  if (
    page < 1 ||
    page > skipLogsPagination.value.total_pages ||
    page === skipLogsPagination.value.current_page ||
    isChangingSkipLogsPage.value
  ) {
    return;
  }

  isChangingSkipLogsPage.value = true;
  try {
    await fetchImport({ requestedSkipLogsPage: page });
  } finally {
    isChangingSkipLogsPage.value = false;
  }
};

const refreshImportInBackground = async () => {
  if (isPolling.value || !hasActiveImport.value || document.hidden) return;

  isPolling.value = true;
  try {
    await fetchImport();
  } finally {
    isPolling.value = false;
    if (!hasActiveImport.value) stopPolling();
  }
};

const abandonImport = async () => {
  isAbandoning.value = true;
  try {
    const response = await DataImportsAPI.abandon(dataImport.value.id);
    dataImport.value = response.data;
    lastUpdatedAt.value = new Date();
    stopPolling();
    useAlert(t('DATA_IMPORTS.ALERTS.IMPORT_ABANDONED'));
  } finally {
    isAbandoning.value = false;
  }
};

const downloadSkipLogs = async () => {
  isDownloadingSkipLogs.value = true;
  try {
    const response = await DataImportsAPI.downloadSkipLogs(dataImport.value.id);
    const url = window.URL.createObjectURL(
      new Blob([response.data], { type: 'text/csv' })
    );
    const link = document.createElement('a');
    link.href = url;
    link.download = `data-import-${dataImport.value.id}-skip-logs.csv`;
    link.click();
    window.URL.revokeObjectURL(url);
  } finally {
    isDownloadingSkipLogs.value = false;
  }
};

const startPolling = () => {
  stopPolling();
  if (!hasActiveImport.value) return;

  pollTimer = window.setInterval(() => {
    refreshImportInBackground();
  }, POLL_INTERVAL_MS);
};

const handleVisibilityChange = () => {
  if (!document.hidden && hasActiveImport.value) {
    refreshImportInBackground();
  }
};

onActivated(async () => {
  await fetchImport({ showLoader: true });
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
        :title="title"
        :description="$t('DATA_IMPORTS.DETAIL.DESCRIPTION')"
        :back-button-label="$t('DATA_IMPORTS.DETAIL.BACK')"
      >
        <template #actions>
          <Button
            ghost
            slate
            size="sm"
            icon="i-lucide-refresh-cw"
            :is-loading="isRefreshing"
            :label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
            @click="fetchImport({ manual: true })"
          />
          <Button
            v-if="canAbandonImport"
            ruby
            size="sm"
            :is-loading="isAbandoning"
            :label="$t('DATA_IMPORTS.TABLE.ABANDON')"
            @click="abandonImport"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div v-if="dataImport" class="flex flex-col gap-4">
        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container p-4"
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
        </section>

        <section class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <div
            v-for="item in summaryItems"
            :key="item.label"
            class="rounded-lg bg-n-card outline outline-1 outline-n-container p-4"
          >
            <div class="text-sm text-n-slate-11">
              {{ item.label }}
            </div>
            <div
              class="mt-2 text-heading-2 text-n-slate-12"
              :class="{ capitalize: item.capitalize }"
            >
              {{ item.value }}
            </div>
          </div>
        </section>

        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container p-4"
        >
          <h2 class="text-heading-3 text-n-slate-12">
            {{ $t('DATA_IMPORTS.DETAIL.METADATA') }}
          </h2>
          <dl class="mt-4 grid gap-x-6 gap-y-4 sm:grid-cols-2">
            <div v-for="item in metadataItems" :key="item.label">
              <dt class="text-sm text-n-slate-11">
                {{ item.label }}
              </dt>
              <dd class="mt-1 text-sm text-n-slate-12">
                {{ item.value || '-' }}
              </dd>
            </div>
          </dl>
        </section>

        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container p-4"
        >
          <h2 class="text-heading-3 text-n-slate-12">
            {{ $t('DATA_IMPORTS.DETAIL.STATS') }}
          </h2>
          <dl class="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <div
              v-for="item in statItems"
              :key="item.label"
              class="border-t border-n-weak pt-3 first:border-t-0 first:pt-0 sm:border-t-0 sm:pt-0"
            >
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
              {{ $t('DATA_IMPORTS.DETAIL.SKIP_LOGS') }}
            </h2>
            <Button
              ghost
              slate
              xs
              icon="i-lucide-download"
              :is-loading="isDownloadingSkipLogs"
              :disabled="!dataImport.skip_logs_count"
              :label="$t('DATA_IMPORTS.DETAIL.DOWNLOAD_SKIP_LOGS')"
              @click="downloadSkipLogs"
            />
          </div>
          <div
            v-if="dataImport.skip_logs_count"
            class="px-4 py-3 border-b border-n-weak flex flex-wrap gap-2"
          >
            <Button
              v-for="option in skipLogTypeOptions"
              :key="option.value || 'all'"
              :variant="
                option.value === selectedSkipLogsType ? 'solid' : 'ghost'
              "
              color="slate"
              size="xs"
              :disabled="!option.count || isChangingSkipLogsPage"
              :label="`${option.label} (${option.count})`"
              @click="changeSkipLogsType(option.value)"
            />
          </div>
          <div v-if="!skipLogs.length" class="p-8 text-center text-n-slate-11">
            {{ $t('DATA_IMPORTS.DETAIL.NO_SKIP_LOGS') }}
          </div>
          <div v-else class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-n-alpha-1 text-n-slate-11">
                <tr>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.KIND') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.SOURCE_OBJECT') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.MESSAGE') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.CREATED') }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="skipLog in skipLogs"
                  :key="skipLog.id"
                  class="border-t border-n-weak text-n-slate-12"
                >
                  <td class="px-4 py-3 capitalize">
                    {{ skipLog.kind || '-' }}
                  </td>
                  <td class="px-4 py-3">
                    {{
                      [skipLog.source_object_type, skipLog.source_object_id]
                        .filter(Boolean)
                        .join(': ') || '-'
                    }}
                  </td>
                  <td class="px-4 py-3">{{ skipLog.message || '-' }}</td>
                  <td class="px-4 py-3">
                    {{ formatDate(skipLog.created_at) }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div
            v-if="hasSkipLogsPagination"
            class="px-4 py-3 border-t border-n-weak flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
          >
            <span class="text-sm text-n-slate-11">
              {{
                $t('DATA_IMPORTS.DETAIL.SKIP_LOGS_PAGE', {
                  current: skipLogsPagination.current_page,
                  total: skipLogsPagination.total_pages,
                  count: skipLogsPagination.total_count,
                })
              }}
            </span>
            <div class="flex items-center gap-2">
              <Button
                ghost
                slate
                xs
                icon="i-lucide-chevron-left"
                :disabled="
                  !canGoToPreviousSkipLogsPage || isChangingSkipLogsPage
                "
                :label="$t('DATA_IMPORTS.DETAIL.PREVIOUS_PAGE')"
                @click="changeSkipLogsPage(skipLogsPagination.current_page - 1)"
              />
              <Button
                ghost
                slate
                xs
                icon="i-lucide-chevron-right"
                trailing-icon
                :disabled="!canGoToNextSkipLogsPage || isChangingSkipLogsPage"
                :label="$t('DATA_IMPORTS.DETAIL.NEXT_PAGE')"
                @click="changeSkipLogsPage(skipLogsPagination.current_page + 1)"
              />
            </div>
          </div>
        </section>

        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container overflow-hidden"
        >
          <div class="px-4 py-3 border-b border-n-weak">
            <h2 class="text-heading-3 text-n-slate-12">
              {{ $t('DATA_IMPORTS.DETAIL.ERRORS') }}
            </h2>
          </div>
          <div
            v-if="!importErrors.length"
            class="p-8 text-center text-n-slate-11"
          >
            {{ $t('DATA_IMPORTS.DETAIL.NO_ERRORS') }}
          </div>
          <div v-else class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-n-alpha-1 text-n-slate-11">
                <tr>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.ERROR_CODE') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.SOURCE_OBJECT') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.MESSAGE') }}
                  </th>
                  <th class="text-left px-4 py-3 font-medium">
                    {{ $t('DATA_IMPORTS.DETAIL.CREATED') }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="error in importErrors"
                  :key="error.id"
                  class="border-t border-n-weak text-n-slate-12"
                >
                  <td class="px-4 py-3">{{ error.error_code }}</td>
                  <td class="px-4 py-3">
                    {{
                      [error.source_object_type, error.source_object_id]
                        .filter(Boolean)
                        .join(': ') || '-'
                    }}
                  </td>
                  <td class="px-4 py-3">{{ error.message || '-' }}</td>
                  <td class="px-4 py-3">
                    {{ formatDate(error.created_at) }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div
            v-if="hasImportErrorsPagination"
            class="px-4 py-3 border-t border-n-weak flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
          >
            <span class="text-sm text-n-slate-11">
              {{
                $t('DATA_IMPORTS.DETAIL.ERROR_LOGS_PAGE', {
                  current: importErrorsPagination.current_page,
                  total: importErrorsPagination.total_pages,
                  count: importErrorsPagination.total_count,
                })
              }}
            </span>
            <div class="flex items-center gap-2">
              <Button
                ghost
                slate
                xs
                icon="i-lucide-chevron-left"
                :disabled="
                  !canGoToPreviousImportErrorsPage || isChangingImportErrorsPage
                "
                :label="$t('DATA_IMPORTS.DETAIL.PREVIOUS_PAGE')"
                @click="
                  changeImportErrorsPage(
                    importErrorsPagination.current_page - 1
                  )
                "
              />
              <Button
                ghost
                slate
                xs
                icon="i-lucide-chevron-right"
                trailing-icon
                :disabled="
                  !canGoToNextImportErrorsPage || isChangingImportErrorsPage
                "
                :label="$t('DATA_IMPORTS.DETAIL.NEXT_PAGE')"
                @click="
                  changeImportErrorsPage(
                    importErrorsPagination.current_page + 1
                  )
                "
              />
            </div>
          </div>
        </section>

        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container p-4"
        >
          <h2 class="text-heading-3 text-n-slate-12">
            {{ $t('DATA_IMPORTS.DETAIL.CONFIGURATION') }}
          </h2>
          <pre :class="codeBlockClass">{{ formattedConfig }}</pre>
        </section>
      </div>
    </template>
  </SettingsLayout>
</template>
