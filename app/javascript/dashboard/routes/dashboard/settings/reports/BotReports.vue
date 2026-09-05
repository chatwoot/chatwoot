<script>
import { ref } from 'vue';
import { useAlert, useTrack } from 'dashboard/composables';
import BotMetrics from './components/BotMetrics.vue';
import BotSummaryTable from './components/BotSummaryTable.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import ReportContainer from './ReportContainer.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportHeader from './components/ReportHeader.vue';
import DownloadDropdown from 'dashboard/components/DownloadDropdown.vue';
import { useReportDownloadOptions } from 'dashboard/composables/useReportDownloadOptions';

export default {
  name: 'BotReports',
  components: {
    BotMetrics,
    BotSummaryTable,
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    DownloadDropdown,
  },
  setup() {
    const downloadingReport = ref(false);
    const botSummaryTableRef = ref(null);
    const { downloadOptions } = useReportDownloadOptions();
    return {
      downloadingReport,
      botSummaryTableRef,
      downloadOptions,
    };
  },
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      selectedInbox: [],
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
        inboxId: this.selectedInbox.length > 0 ? this.selectedInbox : undefined,
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
            inboxIds: this.selectedInbox,
          });
        } catch {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    getRequestPayload() {
      const { from, to, groupBy, businessHours, selectedInbox } = this;

      const payload = {
        from,
        to,
        groupBy: groupBy?.period,
        businessHours,
      };

      if (selectedInbox && selectedInbox.length > 0) {
        payload.inboxId = selectedInbox;
      }

      return payload;
    },
    onFilterChange({ from, to, groupBy, businessHours, selectedInbox }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.selectedInbox = selectedInbox
        ? selectedInbox.map(inbox => inbox.id || inbox)
        : [];
      this.fetchAllData();

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: {
          from,
          to,
          groupBy,
          businessHours,
          selectedInbox: this.selectedInbox,
        },
        reportType: 'bots',
      });
    },
    async downloadReports(option) {
      if (this.$refs.botSummaryTableRef) {
        const format = option?.value || option || 'csv';
        await this.$refs.botSummaryTableRef.downloadReports(format);
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
      show-inbox-filter
      show-group-by-filter
      show-time-range-filter
      :show-business-hours-switch="false"
      @filter-change="onFilterChange"
    />

    <BotMetrics :filters="requestPayload" />

    <ReportContainer
      account-summary-key="getBotSummary"
      summary-fetching-key="getBotSummaryFetchingStatus"
      :group-by="groupBy"
      :report-keys="reportKeys"
      :selected-inbox="selectedInbox"
    />

    <BotSummaryTable
      ref="botSummaryTableRef"
      :from="from"
      :to="to"
      :group-by="groupBy"
      :business-hours="businessHours"
      :selected-inbox="selectedInbox"
    />
  </div>
</template>
