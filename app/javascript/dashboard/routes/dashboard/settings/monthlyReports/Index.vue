<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import MonthlyReportsAPI from 'dashboard/api/monthlyReports';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();

const reports = ref([]);
const isLoading = ref(false);
const downloadingId = ref(null);

const fmtDate = iso => (iso ? new Date(iso).toLocaleString() : '—');

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await MonthlyReportsAPI.list();
    reports.value = data.data || [];
  } catch (error) {
    useAlert(t('MONTHLY_REPORTS.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const download = async report => {
  downloadingId.value = report.id;
  try {
    const res = await MonthlyReportsAPI.download(report.id);
    const url = window.URL.createObjectURL(res.data);
    const a = document.createElement('a');
    a.href = url;
    a.download = `relatorio-elisa-${report.period}.html`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    window.URL.revokeObjectURL(url);
  } catch (error) {
    useAlert(t('MONTHLY_REPORTS.DOWNLOAD_ERROR'));
  } finally {
    downloadingId.value = null;
  }
};

onMounted(load);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('MONTHLY_REPORTS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('MONTHLY_REPORTS.HEADER')"
        :description="$t('MONTHLY_REPORTS.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-3">
        <p
          v-if="!reports.length"
          class="py-16 text-center text-sm text-slate-500 dark:text-slate-400"
        >
          {{ $t('MONTHLY_REPORTS.EMPTY') }}
        </p>

        <div
          v-for="report in reports"
          :key="report.id"
          class="flex items-center justify-between gap-4 p-4 border border-slate-75 dark:border-slate-700 rounded-lg"
        >
          <div class="flex flex-col gap-1 min-w-0">
            <span class="text-sm font-medium text-slate-900 dark:text-slate-50 truncate">
              {{ report.title }}
            </span>
            <span class="text-xs text-slate-500 dark:text-slate-400">
              {{ $t('MONTHLY_REPORTS.GENERATED_AT') }}: {{ fmtDate(report.generated_at) }}
            </span>
          </div>
          <NextButton
            :label="$t('MONTHLY_REPORTS.DOWNLOAD')"
            :is-loading="downloadingId === report.id"
            icon="i-lucide-download"
            class="shrink-0"
            @click="download(report)"
          />
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
