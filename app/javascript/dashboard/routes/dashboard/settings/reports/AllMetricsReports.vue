<script setup>
import { ref } from 'vue';
import ReportHeader from './components/ReportHeader.vue';
import DownloadDropdown from 'dashboard/components/DownloadDropdown.vue';
import AllMetricsFilters from './components/AllMetricsFilters.vue';
import { useReportDownloadOptions } from 'dashboard/composables/useReportDownloadOptions';
import ReportsAPI from 'dashboard/api/reports';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';

const { downloadOptions } = useReportDownloadOptions();

const currentFilters = ref({
  since: null,
  until: null,
  userIds: [],
  teamIds: [],
  inboxIds: [],
});

const sendToEmail = ref(false);
const customEmail = ref('');

const currentUser = useMapGetter('getCurrentUser');

const onFiltersChange = filters => {
  currentFilters.value = filters;
};

const handleEmailDelivery = async format => {
  const params = {
    from: currentFilters.value.since,
    to: currentFilters.value.until,
    format,
    sendEmail: true,
    email: customEmail.value.trim() || undefined,
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

  try {
    const response = await ReportsAPI.getAllMetricsReports(params);

    const recipientEmail =
      response.data.email ||
      customEmail.value.trim() ||
      currentUser.value.email;

    useAlert(`Report queued for delivery to ${recipientEmail}`);
  } catch (error) {
    useAlert('Failed to queue report for email delivery');
  }
};

const handleDirectDownload = async format => {
  const params = {
    from: currentFilters.value.since,
    to: currentFilters.value.until,
    format,
    sendEmail: false,
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

  try {
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
  } catch (error) {
    useAlert('Failed to download report');
  }
};

const handleDownload = async format => {
  if (sendToEmail.value) {
    await handleEmailDelivery(format);
  } else {
    await handleDirectDownload(format);
  }
};
</script>

<template>
  <div>
    <ReportHeader
      :header-title="$t('ALL_METRICS_REPORTS.HEADER')"
      :header-description="$t('ALL_METRICS_REPORTS.DESCRIPTION')"
    >
      <div class="flex flex-col gap-3">
        <DownloadDropdown
          :label="$t('ALL_METRICS_REPORTS.DOWNLOAD')"
          :options="downloadOptions"
          @select="handleDownload"
        />

        <div class="flex flex-col gap-2 text-sm">
          <label class="flex items-center gap-2">
            <input
              v-model="sendToEmail"
              type="checkbox"
              class="rounded border-n-border"
            />
            <span>{{ $t('ALL_METRICS_REPORTS.SEND_TO_EMAIL') }}</span>
          </label>

          <div v-if="sendToEmail" class="flex flex-col gap-1.5">
            <p class="text-xs text-slate-600">
              {{ $t('ALL_METRICS_REPORTS.EMAIL_HINT') }}
            </p>
            <input
              v-model="customEmail"
              type="email"
              :placeholder="currentUser.email"
              class="px-3 py-1.5 text-sm border border-n-border rounded-lg focus:outline-none focus:ring-2 focus:ring-w-500"
            />
          </div>
        </div>
      </div>
    </ReportHeader>
    <div class="mt-6">
      <AllMetricsFilters @filters-change="onFiltersChange" />
    </div>
  </div>
</template>
