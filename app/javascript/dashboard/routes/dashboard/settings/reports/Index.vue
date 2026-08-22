<script>
import V4Button from 'dashboard/components-next/button/Button.vue';
import { useAlert, useTrack } from 'dashboard/composables';
import ReportFilters from './components/ReportFilters.vue';
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
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
  REPLY_TIME: 'reply_time',
};

export default {
  name: 'ConversationReports',
  components: {
    ReportHeader,
    ReportFilters,
    ReportContainer,
    V4Button,
  },
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      businessHours: false,
    };
  },
  methods: {
    fetchAllData() {
      this.fetchAccountSummary();
      this.fetchChartData();
    },
    async fetchAccountSummary() {
      try {
        await this.$store.dispatch(
          'fetchAccountSummary',
          this.getRequestPayload()
        );
      } catch {
        useAlert(this.$t('REPORT.SUMMARY_FETCHING_FAILED'));
      }
    },
    async fetchChartData() {
      const reportKeys = [
        'CONVERSATIONS',
        'INCOMING_MESSAGES',
        'OUTGOING_MESSAGES',
        'FIRST_RESPONSE_TIME',
        'RESOLUTION_TIME',
        'RESOLUTION_COUNT',
        'REPLY_TIME',
      ];
      const results = await Promise.allSettled(
        reportKeys.map(key =>
          this.$store.dispatch('fetchAccountReport', {
            metric: REPORTS_KEYS[key],
            ...this.getRequestPayload(),
          })
        )
      );
      const hasFailure = results.some(result => result.status === 'rejected');
      if (hasFailure) {
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      }
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
    async downloadConversationReports() {
      const { from, to } = this;
      if (!from || !to) {
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        return;
      }
      const fileName = generateFileName({
        type: 'conversation',
        to,
        businessHours: this.businessHours,
      });
      try {
        await this.$store.dispatch('downloadConversationsSummaryReports', {
          from,
          to,
          fileName,
          businessHours: this.businessHours,
        });
      } catch {
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      }
    },
    onFilterChange({ from, to, groupBy, businessHours }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.fetchAllData();

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, groupBy, businessHours },
        reportType: 'conversations',
      });
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('REPORT.HEADER')">
    <V4Button
      :label="$t('REPORT.DOWNLOAD_CONVERSATION_REPORTS')"
      icon="i-ph-download-simple"
      size="sm"
      @click="downloadConversationReports"
    />
  </ReportHeader>
  <div class="flex flex-col">
    <ReportFilters
      :show-entity-filter="false"
      show-group-by
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
