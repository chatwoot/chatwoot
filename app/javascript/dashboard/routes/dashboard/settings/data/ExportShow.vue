<script setup>
import {
  computed,
  ref,
  onActivated,
  onDeactivated,
  onBeforeUnmount,
} from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import DataExportsAPI from 'dashboard/api/dataExports';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { POLL_INTERVAL_MS, formatDate, formatStatus } from './importStatus';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const dataExport = ref(null);
const loading = ref(true);
const busy = ref(false);
const refreshing = ref(false);
let timer;
let active = false;
let generation = 0;
const running = computed(() =>
  ['pending', 'processing'].includes(dataExport.value?.status)
);
const percent = computed(() =>
  dataExport.value?.total_records
    ? Math.min(
        100,
        Math.round(
          (dataExport.value.processed_records * 100) /
            dataExport.value.total_records
        )
      )
    : undefined
);

const refresh = async () => {
  if (refreshing.value) return;
  refreshing.value = true;
  const current = generation;
  try {
    const response = await DataExportsAPI.show(route.params.dataExportId);
    if (active && current === generation) dataExport.value = response.data;
  } catch {
    useAlert(t('DATA_EXPORTS.ERROR'));
  } finally {
    refreshing.value = false;
    loading.value = false;
  }
};
const download = async () => {
  busy.value = true;
  try {
    const response = await DataExportsAPI.download(dataExport.value.id);
    window.location.assign(response.data.download_url);
  } catch {
    useAlert(t('DATA_EXPORTS.DOWNLOAD_ERROR'));
  } finally {
    busy.value = false;
  }
};
const rerun = async () => {
  busy.value = true;
  generation += 1;
  try {
    const response = await DataExportsAPI.rerun(dataExport.value.id);
    dataExport.value = response.data;
    await router.replace({
      name: 'settings_data_export_show',
      params: { ...route.params, dataExportId: response.data.id },
    });
  } catch (error) {
    useAlert(error?.response?.data?.message || t('DATA_EXPORTS.ERROR'));
  } finally {
    busy.value = false;
  }
};
const stop = () => {
  active = false;
  generation += 1;
  window.clearInterval(timer);
};
onActivated(async () => {
  active = true;
  await refresh();
  if (!active) return;
  timer = window.setInterval(() => {
    if (!document.hidden && running.value) refresh();
  }, POLL_INTERVAL_MS);
});
onDeactivated(stop);
onBeforeUnmount(stop);
</script>

<template>
  <SettingsLayout
    :is-loading="loading"
    :loading-message="$t('DATA_IMPORTS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="dataExport?.name || $t('DATA_EXPORTS.TITLE')"
        :back-button-label="$t('DATA_IMPORTS.DETAIL.BACK')"
      >
        <template #actions>
          <Button
            :label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
            slate
            outline
            :is-loading="refreshing"
            @click="refresh"
          />
          <Button
            v-if="dataExport?.can_rerun"
            :label="$t('DATA_EXPORTS.RERUN')"
            slate
            :is-loading="busy"
            @click="rerun"
          />
          <Button
            v-if="dataExport?.downloadable"
            :label="$t('DATA_EXPORTS.DOWNLOAD')"
            :is-loading="busy"
            @click="download"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div
        v-if="dataExport"
        class="flex flex-col gap-4 rounded-xl border border-n-weak bg-n-solid-1 p-5"
      >
        <p class="text-heading-3 text-n-slate-12">
          {{ formatStatus(dataExport.status) }}
        </p>
        <p class="text-body-main text-n-slate-11">
          {{
            $t('DATA_EXPORTS.SCOPE', {
              scope:
                dataExport.export_options.scope_name ||
                dataExport.export_options.label ||
                $t('DATA_EXPORTS.ALL_CONTACTS'),
            })
          }}
        </p>
        <p class="text-body-main text-n-slate-11">
          {{
            $t('DATA_EXPORTS.PROCESSED', {
              count: dataExport.processed_records,
            })
          }}
        </p>
        <progress
          v-if="running"
          :value="percent"
          max="100"
          :aria-label="$t('DATA_IMPORTS.DETAIL.PROGRESS')"
          class="h-2 w-full accent-n-brand"
        />
        <p
          v-if="dataExport.total_records !== null && running"
          class="text-body-main text-n-slate-11"
        >
          {{ $t('DATA_EXPORTS.ESTIMATE', { count: dataExport.total_records }) }}
        </p>
        <p
          v-if="dataExport.error_message"
          role="alert"
          class="text-body-main text-n-ruby-11"
        >
          {{ dataExport.error_message }}
        </p>
        <p
          v-if="dataExport.stalled"
          role="alert"
          class="text-body-main text-n-amber-11"
        >
          {{ $t('DATA_EXPORTS.STALLED') }}
        </p>
        <p
          v-if="dataExport.artifacts_expired_at"
          class="text-body-main text-n-amber-11"
        >
          {{ $t('DATA_EXPORTS.EXPIRED') }}
        </p>
        <p class="text-body-main text-n-slate-11">
          {{
            $t('DATA_EXPORTS.INITIATOR', {
              name: dataExport.initiated_by?.name || '-',
              date: formatDate(dataExport.created_at),
            })
          }}
        </p>
        <p class="text-body-main text-n-slate-11">
          {{ $t('DATA_EXPORTS.RETENTION') }}
        </p>
      </div>
    </template>
  </SettingsLayout>
</template>
