<script>
import { useAlert, useTrack } from 'dashboard/composables';
import AiAgentMetrics from './components/AiAgentMetrics.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import ReportContainer from './ReportContainer.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import ReportHeader from './components/ReportHeader.vue';
import LineChart from '../../../../../shared/components/charts/LineChart.vue';
import ReportLineContainer from './ReportLineContainer.vue';
import ReportsAPI from 'dashboard/api/reports';

export default {
  name: 'AIAgentReports',
  components: {
    AiAgentMetrics,
    ReportHeader,
    ReportFilterSelector,
    ReportContainer,
    LineChart,
    ReportLineContainer,
  },
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      reportKeys: {
        AI_MESSAGE_USAGE: 'ai_agent_credit_usage',
        AI_MESSAGE_SEND_COUNT: 'ai_agent_message_send_count',
        AI_AGENT_HANDOFF_RATE: 'ai_agent_handoff_count',
        AGENT_HANDOFF_RATE: 'agent_handoff_count',
      },
      metrics: {
        aiAgentCreditUsage: 0,
        aiAgentMessageSendCount: 0,
        aiAgentHandoffCount: 0,
        handoffRate: 0,
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
  watch: {
    requestPayload(value) {
      this.fetchMetrics(value);
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
    fetchMetrics(filters) {
      if (!filters.to || !filters.from) {
        return;
      }
      ReportsAPI.getAiAgentMetrics(filters).then(response => {
        this.$data.metrics = {
          aiAgentCreditUsage: response.data.ai_agent_credit_usage,
          aiAgentMessageSendCount: response.data.ai_agent_message_send_count,
          aiAgentHandoffCount: response.data.ai_agent_handoff_count,
          handoffRate: response.data.handoff_rate,
        };
      });
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
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('AI_AGENT_REPORTS.HEADER')" />
  <div class="flex flex-col gap-4">
    <ReportFilterSelector
      :show-agents-filter="false"
      show-group-by-filter
      :show-business-hours-switch="false"
      @filter-change="onFilterChange"
    />

    <ReportLineContainer :metrics="metrics" />
  </div>
</template>
