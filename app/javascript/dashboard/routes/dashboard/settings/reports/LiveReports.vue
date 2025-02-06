<script>
import { mapGetters } from 'vuex';
import MetricCard from './components/overview/MetricCard.vue';
import { OVERVIEW_METRICS } from './constants';

import ReportHeader from './components/ReportHeader.vue';
import HeatmapContainer from './components/HeatmapContainer.vue';
import AgentLiveReportContainer from './components/AgentLiveReportContainer.vue';
export const FETCH_INTERVAL = 60000;

export default {
  name: 'LiveReports',
  components: {
    ReportHeader,
    MetricCard,
    HeatmapContainer,
    AgentLiveReportContainer,
  },
  data() {
    return {
      // always start with 0, this is to manage the pagination in tanstack table
      // when we send the data, we do a +1 to this value
      pageIndex: 0,
    };
  },
  computed: {
    ...mapGetters({
      agentStatus: 'agents/getAgentStatus',
      accountConversationMetric: 'getAccountConversationMetric',
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
    this.initalizeReport();
  },
  beforeUnmount() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }
  },
  methods: {
    initalizeReport() {
      this.fetchAllData();
      this.scheduleReportRefresh();
    },
    scheduleReportRefresh() {
      this.timeoutId = setTimeout(async () => {
        await this.fetchAllData();
        this.scheduleReportRefresh();
      }, FETCH_INTERVAL);
    },
    fetchAllData() {
      this.fetchAccountConversationMetric();
    },
    fetchAccountConversationMetric() {
      this.$store.dispatch('fetchAccountConversationMetric', {
        type: 'account',
      });
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="$t('OVERVIEW_REPORTS.HEADER')" />
  <div class="flex flex-col gap-4 pb-6">
    <div class="flex flex-col items-center md:flex-row gap-4">
      <div
        class="flex-1 w-full max-w-full md:w-[65%] md:max-w-[65%] conversation-metric"
      >
        <MetricCard
          :header="$t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.HEADER')"
          :is-loading="uiFlags.isFetchingAccountConversationMetric"
          :loading-message="$t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.LOADING_MESSAGE')
            "
        >
          <div
            v-for="(metric, name, index) in conversationMetrics"
            :key="index"
            class="flex-1 min-w-0 pb-2"
          >
            <h3 class="text-base text-n-slate-11">
              {{ name }}
            </h3>
            <p class="text-n-slate-12 text-3xl mb-0 mt-1">
              {{ metric }}
            </p>
          </div>
        </MetricCard>
      </div>
      <div class="flex-1 w-full max-w-full md:w-[35%] md:max-w-[35%]">
        <MetricCard :header="$t('OVERVIEW_REPORTS.AGENT_STATUS.HEADER')">
          <div
            v-for="(metric, name, index) in agentStatusMetrics"
            :key="index"
            class="flex-1 min-w-0 pb-2"
          >
            <h3 class="text-base text-n-slate-11">
              {{ name }}
            </h3>
            <p class="text-n-slate-12 text-3xl mb-0 mt-1">
              {{ metric }}
            </p>
          </div>
        </MetricCard>
      </div>
    </div>
    <HeatmapContainer />
    <AgentLiveReportContainer />
  </div>
</template>
