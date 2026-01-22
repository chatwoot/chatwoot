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
import V4Button from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'BotReports',
  components: {
    BotMetrics,
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    V4Button,
  },
  setup() {
    const downloadingReport = ref(false);
    return {
      downloadingReport,
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
    async downloadReports() {
      this.downloadingReport = true;

      const { from, to, groupBy, businessHours } = this;
      const response = await ReportsAPI.getBotReports({
        from,
        to,
        groupBy: groupBy?.period,
        businessHours,
      });

      const blob = new Blob([response.data], { type: 'text/csv' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `bot_summary_${new Date().getTime()}.csv`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);

      useTrack(REPORTS_EVENTS.DOWNLOAD_REPORT, { reportType: 'bots' });
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('BOT_REPORTS.HEADER')">
    <V4Button
      :label="$t('BOT_REPORTS.DOWNLOAD')"
      icon="i-ph-download-simple"
      size="sm"
      :loading="downloadingReport"
      @click="downloadReports"
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
