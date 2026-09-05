import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

export function useReportDownloadOptions() {
  const { t } = useI18n();

  const downloadOptions = computed(() => [
    {
      label: t('REPORT.DOWNLOAD_AS_CSV'),
      value: 'csv',
      icon: 'i-ph-file-csv',
    },
    {
      label: t('REPORT.DOWNLOAD_AS_XLSX'),
      value: 'xlsx',
      icon: 'i-ph-file-xls',
    },
  ]);

  return {
    downloadOptions,
  };
}
