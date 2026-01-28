<script setup>
import { ref } from 'vue';
import ReportHeader from './components/ReportHeader.vue';
import DownloadDropdown from 'dashboard/components/DownloadDropdown.vue';
import AllMetricsFilters from './components/AllMetricsFilters.vue';
import { useReportDownloadOptions } from 'dashboard/composables/useReportDownloadOptions';
import ReportsAPI from 'dashboard/api/reports';

const { downloadOptions } = useReportDownloadOptions();

const currentFilters = ref({
  since: null,
  until: null,
  userIds: [],
  teamIds: [],
  inboxIds: [],
});

const onFiltersChange = filters => {
  currentFilters.value = filters;
};

const handleDownload = async format => {
  const params = {
    format,
    from: currentFilters.value.since,
    to: currentFilters.value.until,
  };

  if (currentFilters.value.userIds && currentFilters.value.userIds.length > 0) {
    params.userIds = currentFilters.value.userIds;
  }

  if (
    currentFilters.value.inboxIds &&
    currentFilters.value.inboxIds.length > 0
  ) {
    params.inboxIds = currentFilters.value.inboxIds;
  }

  if (currentFilters.value.teamIds && currentFilters.value.teamIds.length > 0) {
    params.teamIds = currentFilters.value.teamIds;
  }

  const response = await ReportsAPI.getAllMetricsReports(params);

  const blob = response.data;
  const contentType =
    format === 'xlsx'
      ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      : 'text/csv;charset=utf-8;';

  const url = window.URL.createObjectURL(
    new Blob([blob], { type: contentType })
  );
  const link = document.createElement('a');
  link.href = url;
  link.setAttribute(
    'download',
    `all_conversation_metrics_${Date.now()}.${format}`
  );
  document.body.appendChild(link);
  link.click();

  link.remove();
  window.URL.revokeObjectURL(url);
};
</script>

<template>
  <div>
    <ReportHeader
      :header-title="$t('ALL_METRICS_REPORTS.HEADER')"
      :header-description="$t('ALL_METRICS_REPORTS.DESCRIPTION')"
    >
      <DownloadDropdown
        :label="$t('ALL_METRICS_REPORTS.DOWNLOAD')"
        :options="downloadOptions"
        @select="handleDownload"
      />
    </ReportHeader>
    <div class="mt-6">
      <AllMetricsFilters @filters-change="onFiltersChange" />
    </div>
  </div>
</template>
