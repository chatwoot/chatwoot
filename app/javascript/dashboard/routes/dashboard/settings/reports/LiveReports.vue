<template>
  <div class="flex-1 overflow-auto">
    <div class="p-2">
      <report-filter-selector
        :show-business-hours-switch="false"
        @filter-change="onFilterChange"
      />
    </div>
    <div class="flex flex-col md:flex-row items-center">
      <div
        class="flex-1 w-full max-w-full md:w-[65%] md:max-w-[65%] conversation-metric"
      >
        <metric-card
          :header="$t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.HEADER')"
          :is-loading="uiFlags.isFetchingAccountConversationMetric"
          :loading-message="
            $t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.LOADING_MESSAGE')
          "
        >
          <div
            v-for="(metric, name, index) in conversationMetrics"
            :key="index"
            class="metric-content flex-1 min-w-0"
          >
            <h3 class="heading">
              {{ name }}
            </h3>
            <p class="metric">{{ metric }}</p>
          </div>
        </metric-card>
      </div>
      <div class="flex-1 w-full max-w-full md:w-[35%] md:max-w-[35%]">
        <metric-card :header="$t('OVERVIEW_REPORTS.AGENT_STATUS.HEADER')">
          <div
            v-for="(metric, name, index) in agentStatusMetrics"
            :key="index"
            class="metric-content flex-1 min-w-0"
          >
            <h3 class="heading">
              {{ name }}
            </h3>
            <p class="metric">{{ metric }}</p>
          </div>
        </metric-card>
      </div>
    </div>
    <div class="max-w-full flex flex-wrap flex-row ml-auto mr-auto">
      <metric-card :header="$t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.HEADER')">
        <agent-table
          :agents="agents"
          :agent-metrics="agentConversationMetric"
          :page-index="pageIndex"
          :is-loading="uiFlags.isFetchingAgentConversationMetric"
          @page-change="onPageNumberChange"
        />
      </metric-card>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AgentTable from './components/overview/AgentTable.vue';
import MetricCard from './components/overview/MetricCard.vue';
import { OVERVIEW_METRICS } from './constants';
import ReportFilterSelector from './components/FilterSelector.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  name: 'LiveReports',
  components: {
    ReportFilterSelector,
    AgentTable,
    MetricCard,
  },
  data() {
    return {
      pageIndex: 1,
      from: 0,
      to: 0,
    };
  },
  computed: {
    ...mapGetters({
      agentStatus: 'agents/getAgentStatus',
      agents: 'agents/getAgents',
      accountConversationMetric: 'getAccountConversationMetric',
      agentConversationMetric: 'getAgentConversationMetric',
      uiFlags: 'getOverviewUIFlags',
    }),
    agentStatusMetrics() {
      let metric = {};
      Object.keys(this.agentStatus).forEach(key => {
        const metricName = this.$t(
          `OVERVIEW_REPORTS.AGENT_STATUS.${OVERVIEW_METRICS[key]}`
        );
        metric[metricName] = this.agentStatus[key];
      });
      return metric;
    },
    conversationMetrics() {
      let metric = {};
      Object.keys(this.accountConversationMetric).forEach(key => {
        const metricName = this.$t(
          `OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.${OVERVIEW_METRICS[key]}`
        );
        metric[metricName] = this.accountConversationMetric[key];
      });
      return metric;
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.fetchAllData();

    bus.$on('fetch_overview_reports', () => {
      this.fetchAllData();
    });
  },
  methods: {
    fetchAllData() {
      this.fetchAccountConversationMetric();
      this.fetchAgentConversationMetric();
    },
    fetchAccountConversationMetric() {
      this.$store.dispatch('fetchAccountConversationMetric', {
        type: 'account',
        from: this.from,
        to: this.to,
      });
    },
    fetchAgentConversationMetric() {
      this.$store.dispatch('fetchAgentConversationMetric', {
        type: 'agent',
        page: this.pageIndex,
        from: this.from,
        to: this.to,
      });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.fetchAgentConversationMetric();
    },
    onFilterChange({ from, to }) {
      this.from = from;
      this.to = to;
      this.fetchAllData();

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to },
        reportType: 'conversion',
      });
    },
  },
};
</script>
