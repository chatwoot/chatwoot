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
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import DataOperationStatus from './components/DataOperationStatus.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import { POLL_INTERVAL_MS, formatDate } from './importStatus';

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

const summaryItems = computed(() => [
  {
    label: t('DATA_EXPORTS.SELECTION'),
    icon: 'i-lucide-users',
    value:
      dataExport.value?.export_options.scope_name ||
      dataExport.value?.export_options.label ||
      t('DATA_EXPORTS.ALL_CONTACTS'),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.CREATED'),
    icon: 'i-lucide-calendar',
    value: formatDate(dataExport.value?.created_at),
  },
  {
    label: t('DATA_IMPORTS.DETAIL.INITIATED_BY'),
    icon: 'i-lucide-user',
    value: dataExport.value?.initiated_by?.name || '-',
  },
]);

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
        <template #title>
          <div class="flex w-full flex-wrap items-center justify-between gap-4">
            <h1
              class="min-w-0 max-w-full break-words text-heading-1 text-n-slate-12"
            >
              {{ dataExport?.name || $t('DATA_EXPORTS.TITLE') }}
            </h1>
            <div class="flex shrink-0 items-center gap-2">
              <Button
                v-if="running"
                icon="i-lucide-refresh-cw"
                :aria-label="$t('DATA_IMPORTS.MONITOR.REFRESH')"
                :title="$t('DATA_IMPORTS.MONITOR.REFRESH')"
                slate
                outline
                size="sm"
                :is-loading="refreshing"
                @click="refresh"
              />
              <Button
                v-if="dataExport?.can_rerun"
                :label="$t('DATA_EXPORTS.RERUN')"
                icon="i-lucide-rotate-ccw"
                slate
                outline
                size="sm"
                :is-loading="busy"
                @click="rerun"
              />
              <Button
                v-if="dataExport?.downloadable"
                :label="$t('DATA_EXPORTS.DOWNLOAD')"
                icon="i-lucide-download"
                size="sm"
                :is-loading="busy"
                @click="download"
              />
            </div>
          </div>
        </template>
        <template #description>
          <DataOperationStatus v-if="dataExport" :status="dataExport.status" />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div v-if="dataExport" class="flex flex-col gap-4">
        <dl
          class="grid gap-px overflow-hidden rounded-xl border border-n-weak bg-n-weak sm:grid-cols-3"
        >
          <div
            v-for="item in summaryItems"
            :key="item.label"
            class="flex min-w-0 flex-col gap-2 bg-n-solid-1 px-5 py-4"
          >
            <dt
              class="flex items-center gap-1.5 text-label-small text-n-slate-10"
            >
              <Icon :icon="item.icon" class="size-3.5 shrink-0" />
              {{ item.label }}
            </dt>
            <dd class="break-words text-body-main text-n-slate-12">
              {{ item.value }}
            </dd>
          </div>
        </dl>
        <section
          class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1"
        >
          <h2
            class="border-b border-n-weak px-5 py-4 text-heading-3 text-n-slate-12"
          >
            {{ $t('DATA_EXPORTS.PROGRESS') }}
          </h2>
          <div class="flex flex-col gap-3 px-5 py-4">
            <span class="text-label-small text-n-slate-11">{{
              $t('DATA_EXPORTS.TABLE.EXPORTED')
            }}</span>
            <div class="flex items-end justify-between gap-2">
              <span class="text-heading-1 tabular-nums text-n-slate-12">{{
                dataExport.processed_records.toLocaleString()
              }}</span>
              <span
                v-if="running && percent !== undefined"
                class="text-label-small tabular-nums text-n-slate-11"
              >
                {{ `${percent}%` }}
              </span>
            </div>
            <progress
              v-if="running"
              :value="percent"
              max="100"
              :aria-label="$t('DATA_EXPORTS.PROGRESS')"
              class="h-1.5 w-full appearance-none overflow-hidden rounded-full border-0 bg-n-slate-3 [&::-webkit-progress-bar]:rounded-full [&::-webkit-progress-bar]:bg-n-slate-3 [&::-webkit-progress-value]:rounded-full [&::-webkit-progress-value]:bg-n-brand [&::-moz-progress-bar]:bg-n-brand"
            />
            <p
              v-if="running && dataExport.total_records !== null"
              class="text-label-small text-n-slate-11"
            >
              {{
                $t('DATA_EXPORTS.ESTIMATE', { count: dataExport.total_records })
              }}
            </p>
          </div>
        </section>
        <div
          v-if="dataExport.downloadable"
          class="flex items-start gap-3 rounded-xl border border-n-weak bg-n-solid-1 px-5 py-4"
        >
          <span
            class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-n-teal-3 text-n-teal-11"
          >
            <Icon icon="i-lucide-file-check" class="size-5" />
          </span>
          <div class="flex flex-col gap-1">
            <h2 class="text-heading-3 text-n-slate-12">
              {{ $t('DATA_EXPORTS.FILE_READY') }}
            </h2>
            <p class="text-body-main text-n-slate-11">
              {{ $t('DATA_EXPORTS.RETENTION') }}
            </p>
          </div>
        </div>
        <Banner v-if="running && !dataExport.stalled">
          {{ $t('DATA_EXPORTS.IN_PROGRESS') }}
        </Banner>
        <Banner v-if="dataExport.error_message" color="ruby" role="alert">
          {{ dataExport.error_message }}
        </Banner>
        <Banner v-if="dataExport.stalled" color="amber" role="alert">
          {{ $t('DATA_EXPORTS.STALLED') }}
        </Banner>
        <Banner v-if="dataExport.artifacts_expired_at" color="amber">
          {{ $t('DATA_EXPORTS.EXPIRED') }}
        </Banner>
      </div>
    </template>
  </SettingsLayout>
</template>
