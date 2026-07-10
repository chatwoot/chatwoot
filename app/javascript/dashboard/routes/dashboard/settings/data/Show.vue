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
import formatDistanceStrict from 'date-fns/formatDistanceStrict';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import {
  POLL_INTERVAL_MS,
  importStageKey,
  isAbandonableImport,
  isActiveImport,
} from './importStatus';
import { importSourceFor } from './importSources';

const { t } = useI18n();
const route = useRoute();

const dataImport = ref(null);
const isLoading = ref(true);
const isRefreshing = ref(false);
const isPolling = ref(false);
const isAbandoning = ref(false);
const isDownloadingErrorLogs = ref(false);
const isDownloadingSkipLogs = ref(false);
const isChangingSkipLogsType = ref(false);
const selectedSkipLogsType = ref('');
let pollTimer;

const formatDate = value => {
  if (!value) return '-';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
};

const importErrors = computed(() => dataImport.value?.import_errors || []);

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

const hasActiveImport = computed(() => isActiveImport(dataImport.value));

const isCompletedImport = computed(() =>
  ['completed', 'completed_with_errors'].includes(dataImport.value?.status)
);

const canAbandonImport = computed(() => isAbandonableImport(dataImport.value));

const title = computed(
  () => dataImport.value?.name || t('DATA_IMPORTS.TABLE.UNNAMED')
);

const source = computed(() => importSourceFor(dataImport.value));

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

const importTypeLabel = type => {
  if (type === 'contacts') return t('DATA_IMPORTS.TYPES.CONTACTS');
  if (type === 'conversations') {
    return t('DATA_IMPORTS.TYPES.CONVERSATIONS');
  }
  return type;
};

const importTypesLabel = computed(() => {
  const importTypes = dataImport.value?.import_types?.length
    ? dataImport.value.import_types
    : [dataImport.value?.data_type].filter(Boolean);

  return importTypes.map(importTypeLabel).join(', ');
});

const runDuration = computed(() => {
  const startedAt =
    dataImport.value?.started_at || dataImport.value?.created_at;
  if (!startedAt) return '-';

  const finishedAt =
    dataImport.value?.completed_at ||
    dataImport.value?.abandoned_at ||
    (hasActiveImport.value ? new Date() : dataImport.value?.updated_at);
  if (!finishedAt) return '-';

  return formatDistanceStrict(new Date(startedAt), new Date(finishedAt));
});

const lastUpdatedTooltip = computed(() =>
  t('DATA_IMPORTS.DETAIL.LAST_UPDATED_TOOLTIP', {
    time: formatDate(dataImport.value?.updated_at),
  })
);

const initiatedBy = computed(
  () =>
    dataImport.value?.initiated_by?.name ||
    dataImport.value?.initiated_by?.email ||
    '-'
);

const headerMetadata = computed(() => [
  {
    key: 'source',
    label: t('DATA_IMPORTS.DETAIL.SOURCE'),
    value: source.value.label,
  },
  {
    key: 'import_types',
    label: t('DATA_IMPORTS.DETAIL.IMPORT_TYPES'),
    value: importTypesLabel.value || '-',
  },
  {
    key: 'created_at',
    label: t('DATA_IMPORTS.DETAIL.CREATED'),
    value: formatDate(dataImport.value?.created_at),
  },
  {
    key: 'duration',
    label: t('DATA_IMPORTS.DETAIL.DURATION'),
    value: runDuration.value,
    tooltip: lastUpdatedTooltip.value,
  },
  {
    key: 'initiated_by',
    label: t('DATA_IMPORTS.DETAIL.INITIATED_BY'),
    value: initiatedBy.value,
  },
]);

const progressItems = computed(() => {
  const importTypes = dataImport.value?.import_types || [];
  const groups = [];
  if (importTypes.includes('contacts')) {
    groups.push({
      key: 'contacts',
      label: t('DATA_IMPORTS.TYPES.CONTACTS'),
    });
  }
  if (importTypes.includes('conversations')) {
    groups.push(
      {
        key: 'conversations',
        label: t('DATA_IMPORTS.TYPES.CONVERSATIONS'),
      },
      { key: 'messages', label: t('DATA_IMPORTS.TYPES.MESSAGES') }
    );
  }

  return groups.map(({ key, label }) => {
    const group = key;
    const stats = dataImport.value?.stats?.[group] || {};
    const imported = Number(stats.imported || 0);
    const hasTotal = Object.prototype.hasOwnProperty.call(stats, 'total');
    const total = hasTotal ? Number(stats.total) : null;
    return {
      key: group,
      label,
      value: hasTotal
        ? t('DATA_IMPORTS.DETAIL.PROGRESS_WITH_TOTAL', { imported, total })
        : t('DATA_IMPORTS.DETAIL.PROGRESS_WITHOUT_TOTAL', { imported }),
    };
  });
});

const stopPolling = () => {
  if (!pollTimer) return;

  window.clearInterval(pollTimer);
  pollTimer = null;
};

const fetchImport = async ({
  showLoader = false,
  manual = false,
  requestedSkipLogsType = selectedSkipLogsType.value,
} = {}) => {
  if (showLoader) {
    isLoading.value = true;
  } else if (manual) {
    isRefreshing.value = true;
  }

  try {
    const response = await DataImportsAPI.show(route.params.dataImportId, {
      skip_logs_type: requestedSkipLogsType || undefined,
    });
    dataImport.value = response.data;
    selectedSkipLogsType.value =
      response.data.skip_logs_filters?.selected_source_object_type ||
      requestedSkipLogsType ||
      '';
  } finally {
    if (showLoader) isLoading.value = false;
    if (manual) isRefreshing.value = false;
    if (!hasActiveImport.value) stopPolling();
  }
};

const changeSkipLogsType = async type => {
  if (type === selectedSkipLogsType.value || isChangingSkipLogsType.value) {
    return;
  }

  selectedSkipLogsType.value = type;
  isChangingSkipLogsType.value = true;
  try {
    await fetchImport({
      requestedSkipLogsType: type,
    });
  } finally {
    isChangingSkipLogsType.value = false;
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
    stopPolling();
    useAlert(t('DATA_IMPORTS.ALERTS.IMPORT_ABANDONED'));
  } finally {
    isAbandoning.value = false;
  }
};

const downloadCsv = (response, filename) => {
  const url = window.URL.createObjectURL(
    new Blob([response.data], { type: 'text/csv' })
  );
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  window.URL.revokeObjectURL(url);
};

const downloadErrorLogs = async () => {
  isDownloadingErrorLogs.value = true;
  try {
    const response = await DataImportsAPI.downloadErrorLogs(
      dataImport.value.id
    );
    downloadCsv(response, `data-import-${dataImport.value.id}-error-logs.csv`);
  } finally {
    isDownloadingErrorLogs.value = false;
  }
};

const downloadSkipLogs = async () => {
  isDownloadingSkipLogs.value = true;
  try {
    const response = await DataImportsAPI.downloadSkipLogs(dataImport.value.id);
    downloadCsv(response, `data-import-${dataImport.value.id}-skip-logs.csv`);
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
        :back-button-label="$t('DATA_IMPORTS.DETAIL.BACK')"
      >
        <template #title>
          <div class="flex min-w-0 items-center gap-3">
            <img
              v-if="source.icon"
              :src="source.icon"
              alt=""
              class="size-9 object-contain"
            />
            <Icon
              v-else
              :icon="source.iconClass"
              class="size-9 text-n-slate-10"
            />
            <h1 class="min-w-0 truncate text-heading-1 text-n-slate-12">
              {{ title }}
            </h1>
          </div>
        </template>
        <template #actions>
          <Button
            v-if="!isCompletedImport"
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
          class="rounded-lg bg-n-card px-4 py-3 outline outline-1 outline-n-container"
        >
          <div class="flex flex-col gap-3 lg:flex-row lg:items-center">
            <div
              class="flex shrink-0 flex-wrap items-center gap-x-3 gap-y-1 text-sm"
            >
              <span
                class="inline-flex items-center gap-1.5 font-medium text-n-slate-12"
              >
                <span
                  class="size-2 rounded-full"
                  :class="
                    hasActiveImport
                      ? 'bg-n-teal-9 animate-pulse'
                      : 'bg-n-slate-8'
                  "
                />
                {{ monitorTitle }}
              </span>
              <span v-if="hasActiveImport" class="text-n-teal-11">
                {{
                  isPolling
                    ? $t('DATA_IMPORTS.MONITOR.REFRESHING')
                    : $t('DATA_IMPORTS.MONITOR.LIVE', {
                        seconds: POLL_INTERVAL_MS / 1000,
                      })
                }}
              </span>
            </div>
            <dl
              class="grid flex-1 grid-cols-2 gap-x-4 gap-y-2 border-t border-n-weak pt-3 sm:grid-cols-3 lg:grid-cols-5 lg:border-l lg:border-t-0 lg:pl-4 lg:pt-0"
            >
              <div
                v-for="item in headerMetadata"
                :key="item.key"
                class="min-w-0"
              >
                <dt class="text-xs text-n-slate-10">{{ item.label }}</dt>
                <dd
                  v-tooltip.top="item.tooltip"
                  class="truncate text-sm font-medium text-n-slate-12"
                >
                  {{ item.value }}
                </dd>
              </div>
            </dl>
          </div>
        </section>

        <section
          class="overflow-hidden rounded-lg bg-n-card outline outline-1 outline-n-container"
        >
          <div class="border-b border-n-weak px-4 py-3">
            <h2 class="text-heading-3 text-n-slate-12">
              {{ $t('DATA_IMPORTS.DETAIL.PROGRESS') }}
            </h2>
          </div>
          <div
            v-for="item in progressItems"
            :key="item.key"
            class="border-t border-n-weak px-4 py-4 first:border-t-0"
          >
            <div class="flex items-center justify-between gap-4 text-sm">
              <span class="font-medium text-n-slate-12">{{ item.label }}</span>
              <span class="text-n-slate-11">{{ item.value }}</span>
            </div>
          </div>
        </section>

        <section
          class="rounded-lg bg-n-card outline outline-1 outline-n-container overflow-hidden"
        >
          <div
            class="px-4 py-3 border-b border-n-weak flex items-center justify-between gap-3"
          >
            <h2 class="text-heading-3 text-n-slate-12">
              {{ $t('DATA_IMPORTS.DETAIL.ERRORS') }}
            </h2>
            <Button
              ghost
              slate
              xs
              icon="i-lucide-download"
              :is-loading="isDownloadingErrorLogs"
              :disabled="!dataImport.import_errors_count"
              :label="$t('DATA_IMPORTS.DETAIL.DOWNLOAD_ERROR_LOGS')"
              @click="downloadErrorLogs"
            />
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
              :disabled="!option.count || isChangingSkipLogsType"
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
        </section>
      </div>
    </template>
  </SettingsLayout>
</template>
