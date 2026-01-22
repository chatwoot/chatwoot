<script>
import { ref } from 'vue';
import { useAlert, useTrack } from 'dashboard/composables';
import BotMetrics from './components/BotMetrics.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import ReportContainer from './ReportContainer.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportHeader from './components/ReportHeader.vue';
import ReportsAPI from 'dashboard/api/reports';
import DownloadDropdown from 'dashboard/components/DownloadDropdown.vue';
import { useReportDownloadOptions } from 'dashboard/composables/useReportDownloadOptions';

export default {
  name: 'BotReports',
  components: {
    BotMetrics,
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    DownloadDropdown,
  },
  setup() {
    const downloadingReport = ref(false);
    const { downloadOptions } = useReportDownloadOptions();
    return {
      downloadingReport,
      downloadOptions,
    };
  },
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      reportKeys: {
        BOT_RESOLUTION_COUNT: 'bot_resolutions_count',
        BOT_HANDOFF_COUNT: 'bot_handoffs_count',
      },
      businessHours: false,
    };
  },
  computed: {
    requestPayload() {
      return {
        from: this.from,
        to: this.to,
      };
    },
  },
  methods: {
    fetchAllData() {
      this.fetchBotSummary();
      this.fetchChartData();
    },
    fetchBotSummary() {
      try {
        this.$store.dispatch('fetchBotSummary', this.getRequestPayload());
      } catch {
        useAlert(this.$t('REPORT.SUMMARY_FETCHING_FAILED'));
      }
    },
    fetchChartData() {
      Object.keys(this.reportKeys).forEach(async key => {
        try {
          await this.$store.dispatch('fetchAccountReport', {
            metric: this.reportKeys[key],
            ...this.getRequestPayload(),
          });
        } catch {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    getRequestPayload() {
      const { from, to, groupBy, businessHours } = this;

      return {
        from,
        to,
        groupBy: groupBy?.period,
        businessHours,
      };
    },
    onFilterChange({ from, to, groupBy, businessHours }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.fetchAllData();

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, groupBy, businessHours },
        reportType: 'bots',
      });
    },
    async downloadReports(option) {
      this.downloadingReport = true;

      const format = option?.value || option || 'csv'; // Извлекаем формат из объекта опции
      const { from, to, groupBy, businessHours } = this;

      try {
        const response = await ReportsAPI.getBotReports({
          from,
          to,
          groupBy: groupBy?.period,
          businessHours,
          format,
        });

        const mimeTypes = {
          csv: 'text/csv',
          xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        };

        const blob = new Blob([response.data], { type: mimeTypes[format] });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `bot_summary_${new Date().getTime()}.${format}`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);

        useTrack(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'bots',
          format: format,
        });
      } catch (error) {
        useAlert(this.$t('BOT_REPORTS.DOWNLOAD_FAILED'));
      } finally {
        this.downloadingReport = false;
      }
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('BOT_REPORTS.HEADER')">
    <DownloadDropdown
      :label="$t('BOT_REPORTS.DOWNLOAD')"
      :options="downloadOptions"
      :loading="downloadingReport"
      @select="downloadReports"
    />
  </ReportHeader>

  <div class="flex flex-col gap-4">
    <ReportFilterSelector
      :show-agents-filter="false"
      show-group-by-filter
      :show-business-hours-switch="false"
      @filter-change="onFilterChange"
    />

    <BotMetrics :filters="requestPayload" />
    <ReportContainer
      account-summary-key="getBotSummary"
      summary-fetching-key="getBotSummaryFetchingStatus"
      :group-by="groupBy"
      :report-keys="reportKeys"
    />
  </div>
</template>
