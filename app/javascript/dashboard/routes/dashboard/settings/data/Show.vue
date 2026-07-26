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

import DataImportsAPI from 'dashboard/api/dataImports';
import { POLL_INTERVAL_MS, isActiveImport } from './importStatus';
import SettingsLayout from '../SettingsLayout.vue';
import ImportDetailHeader from './components/ImportDetailHeader.vue';
import ImportSummaryTiles from './components/ImportSummaryTiles.vue';
import ImportProgress from './components/ImportProgress.vue';
import ImportErrorsSection from './components/ImportErrorsSection.vue';
import ImportSkipLogsSection from './components/ImportSkipLogsSection.vue';

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
let isPageActive = false;

const hasActiveImport = computed(() => isActiveImport(dataImport.value));

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
    await fetchImport({ requestedSkipLogsType: type });
  } finally {
    isChangingSkipLogsType.value = false;
  }
};

const refreshImportInBackground = async () => {
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
  if (!isPageActive || !hasActiveImport.value) return;

  pollTimer = window.setInterval(refreshImportInBackground, POLL_INTERVAL_MS);
};

const handleVisibilityChange = () => {
  if (isPageActive && !document.hidden && hasActiveImport.value) {
    refreshImportInBackground();
  }
};

onActivated(async () => {
  isPageActive = true;
  await fetchImport({ showLoader: true });
  if (!isPageActive) return;

  // Collapse empty sections by default; expand the ones with records.
  errorsOpen.value = Boolean(dataImport.value?.import_errors_count);
  skipLogsOpen.value = Boolean(dataImport.value?.skip_logs_count);
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
      <ImportDetailHeader
        :data-import="dataImport"
        :is-refreshing="isRefreshing"
        :is-abandoning="isAbandoning"
        :is-polling="isPolling"
        @refresh="fetchImport({ manual: true })"
        @abandon="abandonImport"
      />
    </template>

    <template #body>
      <div v-if="dataImport" class="flex flex-col gap-3">
        <ImportSummaryTiles :data-import="dataImport" />

        <ImportProgress
          v-if="dataImport.import_types?.length"
          :data-import="dataImport"
          :title="$t('DATA_IMPORTS.DETAIL.PROGRESS')"
        />

        <ImportErrorsSection
          :data-import="dataImport"
          :is-open="errorsOpen"
          :is-downloading="isDownloadingErrorLogs"
          @toggle="errorsOpen = !errorsOpen"
          @download="downloadErrorLogs"
        />

        <ImportSkipLogsSection
          :data-import="dataImport"
          :is-open="skipLogsOpen"
          :is-downloading="isDownloadingSkipLogs"
          :selected-type="selectedSkipLogsType"
          :is-changing-type="isChangingSkipLogsType"
          @toggle="skipLogsOpen = !skipLogsOpen"
          @download="downloadSkipLogs"
          @change-type="changeSkipLogsType"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
