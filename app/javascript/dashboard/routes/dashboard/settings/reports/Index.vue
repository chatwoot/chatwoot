<script>
import DownloadDropdown from 'dashboard/components/DownloadDropdown.vue';
import { useReportDownloadOptions } from 'dashboard/composables/useReportDownloadOptions';
import { useAlert, useTrack } from 'dashboard/composables';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import { generateFileName } from 'dashboard/helper/downloadHelper';
import ReportContainer from './ReportContainer.vue';
import ReportHeader from './components/ReportHeader.vue';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME_WITHOUT_BOT: 'avg_resolution_time_without_bot',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
  REPLY_TIME: 'reply_time',
};

export default {
  name: 'ConversationReports',
  components: {
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    DownloadDropdown,
  },
  setup() {
    const { downloadOptions } = useReportDownloadOptions();
    return { downloadOptions };
  },
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      businessHours: false,
      selectedAgents: [],
      selectedInboxes: [],
      timeRange: {
        since: '00:00',
        until: '23:59',
      },
    };
  },
  methods: {
    fetchAllData() {
      this.fetchAccountSummary();
      this.fetchChartData();
    },
    fetchAccountSummary() {
      try {
        this.$store.dispatch('fetchAccountSummary', this.getRequestPayload());
      } catch {
        useAlert(this.$t('REPORT.SUMMARY_FETCHING_FAILED'));
      }
    },
    fetchChartData() {
      [
        'CONVERSATIONS',
        'INCOMING_MESSAGES',
        'OUTGOING_MESSAGES',
        'FIRST_RESPONSE_TIME',
        'RESOLUTION_TIME',
        'RESOLUTION_TIME_WITHOUT_BOT',
        'RESOLUTION_COUNT',
        'REPLY_TIME',
      ].forEach(async key => {
        try {
          await this.$store.dispatch('fetchAccountReport', {
            metric: REPORTS_KEYS[key],
            ...this.getRequestPayload(),
          });
        } catch {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    getRequestPayload() {
      const {
        from,
        to,
        groupBy,
        businessHours,
        timeRange,
        selectedAgents,
        selectedInboxes,
      } = this;

      return {
        from,
        to,
        groupBy: groupBy?.period,
        businessHours,
        timeRange,
        userIds: selectedAgents.map(agent => agent.id),
        inboxIds: selectedInboxes.map(inbox => inbox.id),
      };
    },
    downloadConversationReports(option) {
      const { from, to, timeRange, selectedAgents, selectedInboxes } = this;
      const format = option?.value || option || 'csv';
      const fileName = generateFileName({
        type: 'conversation',
        to,
        businessHours: this.businessHours,
        format,
      });
      this.$store.dispatch('downloadConversationsSummaryReports', {
        from,
        to,
        format,
        fileName,
        businessHours: this.businessHours,
        timeRange,
        userIds: selectedAgents.map(agent => agent.id),
        inboxIds: selectedInboxes.map(inbox => inbox.id),
      });
    },
    onFilterChange({
      from,
      to,
      groupBy,
      businessHours,
      timeRange,
      selectedAgents,
      selectedInbox,
    }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.timeRange = timeRange;
      this.selectedAgents = selectedAgents || [];
      this.selectedInboxes = selectedInbox || [];
      this.fetchAllData();

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, groupBy, businessHours, timeRange },
        reportType: 'conversations',
      });
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('REPORT.HEADER')">
    <DownloadDropdown
      :label="$t('REPORT.DOWNLOAD_CONVERSATION_REPORTS')"
      :options="downloadOptions"
      @select="downloadConversationReports"
    />
  </ReportHeader>
  <div class="flex flex-col gap-3">
    <ReportFilterSelector
      show-agents-filter
      show-inbox-filter
      show-group-by-filter
      show-time-range-filter
      @filter-change="onFilterChange"
    />
    <ReportContainer
      :group-by="groupBy"
      :from="from"
      :to="to"
      :business-hours="businessHours"
    />
  </div>
</template>
