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
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import DataImportsAPI from 'dashboard/api/dataImports';
import {
  POLL_INTERVAL_MS,
  formatDate,
  importStageKey,
  isAbandonableImport,
  isActiveImport,
  statusDotClass as getStatusDotClass,
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
const errorsOpen = ref(true);
const skipLogsOpen = ref(true);
let pollTimer;

const importErrors = computed(() => dataImport.value?.import_errors || []);

const skipLogs = computed(() => dataImport.value?.skip_logs || []);

const errorHeaders = computed(() => [
  t('DATA_IMPORTS.DETAIL.ERROR_CODE'),
  t('DATA_IMPORTS.DETAIL.SOURCE_OBJECT'),
  t('DATA_IMPORTS.DETAIL.MESSAGE'),
  t('DATA_IMPORTS.DETAIL.CREATED'),
]);

const skipLogHeaders = computed(() => [
  t('DATA_IMPORTS.DETAIL.KIND'),
  t('DATA_IMPORTS.DETAIL.SOURCE_OBJECT'),
  t('DATA_IMPORTS.DETAIL.MESSAGE'),
  t('DATA_IMPORTS.DETAIL.CREATED'),
]);

const sourceObjectLabel = record =>
  [record.source_object_type, record.source_object_id]
    .filter(Boolean)
    .join(': ') || '-';

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

const statusDotClass = computed(() =>
  getStatusDotClass(dataImport.value?.status)
);

const headerMetadata = computed(() => [
  {
    key: 'source',
    icon: 'i-lucide-plug',
    label: t('DATA_IMPORTS.DETAIL.SOURCE'),
    value: source.value.label,
  },
  {
    key: 'import_types',
    icon: 'i-lucide-layers',
    label: t('DATA_IMPORTS.DETAIL.IMPORT_TYPES'),
    value: importTypesLabel.value || '-',
  },
  {
    key: 'created_at',
    icon: 'i-lucide-calendar',
    label: t('DATA_IMPORTS.DETAIL.CREATED'),
    value: formatDate(dataImport.value?.created_at),
  },
  {
    key: 'duration',
    icon: 'i-lucide-clock',
    label: t('DATA_IMPORTS.DETAIL.DURATION'),
    value: runDuration.value,
    tooltip: lastUpdatedTooltip.value,
  },
  {
    key: 'initiated_by',
    icon: 'i-lucide-user',
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
    const percent =
      hasTotal && total > 0
        ? Math.min(100, Math.round((imported / total) * 100))
        : null;
    return {
      key: group,
      label,
      hasTotal,
      total,
      percent,
      importedLabel: imported.toLocaleString(),
      caption: hasTotal
        ? t('DATA_IMPORTS.DETAIL.PROGRESS_OF_TOTAL', {
            total: total.toLocaleString(),
          })
        : t('DATA_IMPORTS.DETAIL.PROGRESS_IMPORTED'),
    };
  });
});

const progressColsClass = computed(() => {
  if (progressItems.value.length >= 3) return 'sm:grid-cols-3';
  if (progressItems.value.length === 2) return 'sm:grid-cols-2';
  return 'sm:grid-cols-1';
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
  // Collapse empty sections by default; expand the ones with records.
  errorsOpen.value = Boolean(dataImport.value?.import_errors_count);
  skipLogsOpen.value = Boolean(dataImport.value?.skip_logs_count);
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
          <div class="flex w-full items-center justify-between gap-4">
            <h1 class="min-w-0 truncate text-heading-1 text-n-slate-12">
              {{ title }}
            </h1>
            <div class="flex shrink-0 items-center gap-2">
              <Button
                v-if="hasActiveImport"
                outline
                slate
                size="sm"
                icon="i-lucide-refresh-cw"
                :is-loading="isRefreshing"
                :aria-label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
                :title="$t('DATA_IMPORTS.MONITOR.REFRESH')"
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
            </div>
          </div>
        </template>
        <template #description>
          <span class="inline-flex items-center gap-1.5 align-middle">
            <span
              class="size-2 rounded-full"
              :class="[statusDotClass, { 'animate-pulse': hasActiveImport }]"
            />
            {{ monitorTitle }}
          </span>
          <template v-if="hasActiveImport">
            <span
              class="mx-2 inline-block h-3 w-px rounded-lg bg-n-strong align-middle"
            />
            <span class="text-n-teal-11">
              {{
                isPolling
                  ? $t('DATA_IMPORTS.MONITOR.REFRESHING')
                  : $t('DATA_IMPORTS.MONITOR.LIVE', {
                      seconds: POLL_INTERVAL_MS / 1000,
                    })
              }}
            </span>
          </template>
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <div v-if="dataImport" class="flex flex-col gap-3">
        <!-- Metadata: divided summary tiles (matches the progress grid) -->
        <dl
          class="grid grid-cols-2 gap-px overflow-hidden rounded-xl border border-n-weak bg-n-weak sm:grid-cols-3 lg:grid-cols-5"
        >
          <div
            v-for="item in headerMetadata"
            :key="item.key"
            class="flex min-w-0 flex-col gap-1 bg-n-solid-1 px-4 py-3"
          >
            <dt
              class="flex items-center gap-1.5 text-label-small text-n-slate-10"
            >
              <Icon :icon="item.icon" class="size-3.5 shrink-0" />
              {{ item.label }}
            </dt>
            <dd
              v-tooltip.top="item.tooltip"
              class="truncate text-heading-3 text-n-slate-12"
            >
              {{ item.value }}
            </dd>
          </div>
        </dl>

        <!-- Import progress: compact side-by-side columns -->
        <section
          v-if="progressItems.length"
          class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1"
        >
          <h2
            class="border-b border-n-weak px-4 py-3 text-heading-3 text-n-slate-12"
          >
            {{ $t('DATA_IMPORTS.DETAIL.PROGRESS') }}
          </h2>
          <div
            class="grid grid-cols-1 gap-px bg-n-weak"
            :class="progressColsClass"
          >
            <div
              v-for="item in progressItems"
              :key="item.key"
              class="flex flex-col gap-2 bg-n-solid-1 px-4 py-3"
            >
              <span class="text-label-small text-n-slate-11">
                {{ item.label }}
              </span>
              <div class="flex items-end justify-between gap-2">
                <span
                  class="text-xl font-semibold tracking-tight tabular-nums text-n-slate-12"
                >
                  {{ item.importedLabel }}
                </span>
                <span
                  v-if="item.percent !== null"
                  class="text-label-small tabular-nums text-n-slate-11"
                >
                  {{ `${item.percent}%` }}
                </span>
              </div>
              <div
                v-if="item.percent !== null"
                class="h-1.5 w-full overflow-hidden rounded-full bg-n-alpha-2"
              >
                <div
                  class="h-full rounded-full bg-n-brand transition-all duration-500"
                  :style="{ width: `${item.percent}%` }"
                />
              </div>
              <span class="text-label-small text-n-slate-10">
                {{ item.caption }}
              </span>
            </div>
          </div>
        </section>

        <!-- Errors -->
        <section
          class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1"
        >
          <div class="flex items-center justify-between gap-3 px-4 py-3">
            <button
              type="button"
              class="flex min-w-0 items-center gap-2 !p-0"
              :aria-expanded="errorsOpen"
              @click="errorsOpen = !errorsOpen"
            >
              <h2 class="text-heading-3 text-n-slate-12">
                {{ $t('DATA_IMPORTS.DETAIL.ERRORS') }}
              </h2>
              <span
                v-if="dataImport.import_errors_count"
                class="rounded-md bg-n-alpha-2 px-1.5 text-label-small tabular-nums text-n-slate-11"
              >
                {{ dataImport.import_errors_count }}
              </span>
              <Icon
                icon="i-lucide-chevron-down"
                class="size-4 shrink-0 text-n-slate-10 transition-transform duration-200"
                :class="{ '-rotate-90 rtl:rotate-90': !errorsOpen }"
              />
            </button>
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
            class="grid transition-[grid-template-rows] duration-300 ease-in-out"
            :class="errorsOpen ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'"
          >
            <div class="min-h-0 overflow-hidden">
              <div class="border-t border-n-weak">
                <p
                  v-if="!importErrors.length"
                  class="px-4 py-8 text-center text-body-main text-n-slate-11"
                >
                  {{ $t('DATA_IMPORTS.DETAIL.NO_ERRORS') }}
                </p>
                <div v-else class="overflow-x-auto">
                  <BaseTable
                    class="[&_td:first-child]:ps-4 [&_th:first-child]:ps-4 [&_th]:text-n-slate-11 [&_thead]:border-t-0"
                    :headers="errorHeaders"
                    :items="importErrors"
                  >
                    <template #row="{ items }">
                      <BaseTableRow
                        v-for="error in items"
                        :key="error.id"
                        :item="error"
                      >
                        <template #default>
                          <BaseTableCell>
                            <span class="text-body-main text-n-slate-12">
                              {{ error.error_code }}
                            </span>
                          </BaseTableCell>
                          <BaseTableCell>
                            <span class="text-body-main text-n-slate-12">
                              {{ sourceObjectLabel(error) }}
                            </span>
                          </BaseTableCell>
                          <BaseTableCell>
                            <span class="text-body-main text-n-slate-11">
                              {{ error.message || '-' }}
                            </span>
                          </BaseTableCell>
                          <BaseTableCell>
                            <span
                              class="whitespace-nowrap text-body-main text-n-slate-11"
                            >
                              {{ formatDate(error.created_at) }}
                            </span>
                          </BaseTableCell>
                        </template>
                      </BaseTableRow>
                    </template>
                  </BaseTable>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- Skip logs -->
        <section
          class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1"
        >
          <div class="flex items-center justify-between gap-3 px-4 py-3">
            <button
              type="button"
              class="flex min-w-0 items-center gap-2 !p-0"
              :aria-expanded="skipLogsOpen"
              @click="skipLogsOpen = !skipLogsOpen"
            >
              <h2 class="text-heading-3 text-n-slate-12">
                {{ $t('DATA_IMPORTS.DETAIL.SKIP_LOGS') }}
              </h2>
              <span
                v-if="dataImport.skip_logs_count"
                class="rounded-md bg-n-alpha-2 px-1.5 text-label-small tabular-nums text-n-slate-11"
              >
                {{ dataImport.skip_logs_count }}
              </span>
              <Icon
                icon="i-lucide-chevron-down"
                class="size-4 shrink-0 text-n-slate-10 transition-transform duration-200"
                :class="{ '-rotate-90 rtl:rotate-90': !skipLogsOpen }"
              />
            </button>
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
            class="grid transition-[grid-template-rows] duration-300 ease-in-out"
            :class="skipLogsOpen ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'"
          >
            <div class="min-h-0 overflow-hidden">
              <div class="border-t border-n-weak">
                <div
                  v-if="dataImport.skip_logs_count"
                  class="flex flex-wrap gap-2 border-b border-n-weak px-4 py-3"
                >
                  <Button
                    v-for="option in skipLogTypeOptions"
                    :key="option.value || 'all'"
                    :variant="
                      option.value === selectedSkipLogsType ? 'solid' : 'faded'
                    "
                    color="slate"
                    size="xs"
                    :disabled="!option.count || isChangingSkipLogsType"
                    :label="`${option.label} (${option.count})`"
                    @click="changeSkipLogsType(option.value)"
                  />
                </div>
                <p
                  v-if="!skipLogs.length"
                  class="px-4 py-8 text-center text-body-main text-n-slate-11"
                >
                  {{ $t('DATA_IMPORTS.DETAIL.NO_SKIP_LOGS') }}
                </p>
                <div v-else class="overflow-x-auto">
                  <BaseTable
                    class="[&_td:first-child]:ps-4 [&_th:first-child]:ps-4 [&_th]:text-n-slate-11 [&_thead]:border-t-0"
                    :headers="skipLogHeaders"
                    :items="skipLogs"
                  >
                    <template #row="{ items }">
                      <BaseTableRow
                        v-for="skipLog in items"
                        :key="skipLog.id"
                        :item="skipLog"
                      >
                        <template #default>
                          <BaseTableCell>
                            <span
                              class="capitalize text-body-main text-n-slate-12"
                            >
                              {{ skipLog.kind || '-' }}
                            </span>
                          </BaseTableCell>
                          <BaseTableCell>
                            <span class="text-body-main text-n-slate-11">
                              {{ sourceObjectLabel(skipLog) }}
                            </span>
                          </BaseTableCell>
                          <BaseTableCell>
                            <span class="text-body-main text-n-slate-11">
                              {{ skipLog.message || '-' }}
                            </span>
                          </BaseTableCell>
                          <BaseTableCell>
                            <span
                              class="whitespace-nowrap text-body-main text-n-slate-11"
                            >
                              {{ formatDate(skipLog.created_at) }}
                            </span>
                          </BaseTableCell>
                        </template>
                      </BaseTableRow>
                    </template>
                  </BaseTable>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </template>
  </SettingsLayout>
</template>
