<script>
import { mapGetters } from 'vuex';
import AgentTable from './components/overview/AgentTable.vue';
import MetricCard from './components/overview/MetricCard.vue';
import { OVERVIEW_METRICS } from './constants';
import ReportHeatmap from './components/Heatmap.vue';

import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import ReportHeader from './components/ReportHeader.vue';
export const FETCH_INTERVAL = 60000;
import ConversationAnalytics from './Index.vue';
import Csat from './CsatResponses.vue';
import AgentReports from './AgentReports.vue';

export default {
  name: 'LiveReports',
  components: {
    ReportHeader,
    AgentTable,
    MetricCard,
    ReportHeatmap,
    ConversationAnalytics,
    Csat,
    AgentReports,
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
      agents: 'agents/getAgents',
      accountConversationMetric: 'getAccountConversationMetric',
      agentConversationMetric: 'getAgentConversationMetric',
      accountConversationHeatmap: 'getAccountConversationHeatmapData',
      uiFlags: 'getOverviewUIFlags',
      creditUsageMetric: 'getCreditUsageMetric',
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
      this.fetchAgentConversationMetric();
      this.fetchHeatmapData();
      this.fetchCreditUsageMetric();
    },
    downloadHeatmapData() {
      let to = endOfDay(new Date());

      this.$store.dispatch('downloadAccountConversationHeatmap', {
        to: getUnixTime(to),
      });
    },
    fetchHeatmapData() {
      if (this.uiFlags.isFetchingAccountConversationsHeatmap) {
        return;
      }

      // the data for the last 6 days won't ever change,
      // so there's no need to fetch it again
      // but we can write some logic to check if the data is already there
      // if it is there, we can refetch data only for today all over again
      // and reconcile it with the rest of the data
      // this will reduce the load on the server doing number crunching
      let to = endOfDay(new Date());
      let from = startOfDay(subDays(to, 6));

      if (this.accountConversationHeatmap.length) {
        to = endOfDay(new Date());
        from = startOfDay(to);
      }

      this.$store.dispatch('fetchAccountConversationHeatmap', {
        metric: 'conversations_count',
        from: getUnixTime(from),
        to: getUnixTime(to),
        groupBy: 'hour',
        businessHours: false,
      });
    },
    fetchAccountConversationMetric() {
      this.$store.dispatch('fetchAccountConversationMetric', {
        type: 'account',
      });
    },
    fetchAgentConversationMetric() {
      this.$store.dispatch('fetchAgentConversationMetric', {
        type: 'agent',
        page: this.pageIndex + 1,
      });
    },
    fetchCreditUsageMetric() {
      this.$store.dispatch('fetchCreditUsageMetric', {
        type: 'account',
      });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.fetchAgentConversationMetric();
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
          :loading-message="
            $t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.LOADING_MESSAGE')
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
              {{ accountConversationMetric?.open || 0 }}
            </p>
          </div>
          <div class="flex-1 min-w-0 pb-2 pr-2">
            <h3 class="text-sm">
              {{ $t('OVERVIEW_REPORTS.CHAT_SUMMARY.CHAT_ANSWERED_BY_AI') }}
            </h3>
            <p class="text-n-slate-12 text-3xl mb-0 mt-1">
              {{ creditUsageMetric?.ai_responses || 0 }}
            </p>
          </div>
          <div class="flex-1 min-w-0 pb-2 pr-2">
            <h3 class="text-sm">
              {{ $t('OVERVIEW_REPORTS.CHAT_SUMMARY.RESOLVED_PERCENTAGE') }}
            </h3>
            <p class="text-n-slate-12 text-3xl mb-0 mt-1">
              {{ accountConversationMetric?.ai_responses/accountConversationMetric?.open * 100 || 0 }}%
            </p>
          </div>
          <div class="flex-1 min-w-0 pb-2 pr-2">
            <h3 class="text-sm">
              {{ $t('OVERVIEW_REPORTS.CHAT_SUMMARY.CHAT_HANDOVERED') }}
            </h3>
            <p class="text-n-slate-12 text-3xl mb-0 mt-1">
              {{ accountConversationMetric?.unassigned || 0 }}
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
    <div class="flex flex-col items-center md:flex-row gap-4">
      <div class="flex-1 w-full max-w-full">
        <MetricCard
          header="Jawaban AI"
          :is-loading="uiFlags.isFetchingCreditUsage"
        >
          <div class="flex-1 min-w-0 pb-2">
            <p class="text-n-slate-12 text-3xl mb-0 mt-1">
              {{
                // TODO: add localization
                creditUsageMetric?.credit_usage
                  ? `${creditUsageMetric?.credit_usage} terpakai`
                  : '-'
              }}
            </p>
          </div>
        </MetricCard>
      </div>
    </div>
    <div class="flex flex-row flex-wrap max-w-full">
      <MetricCard :header="$t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.HEADER')">
        <template #control>
          <woot-button
            icon="arrow-download"
            size="small"
            variant="smooth"
            color-scheme="secondary"
            @click="downloadHeatmapData"
          >
            {{ $t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.DOWNLOAD_REPORT') }}
          </woot-button>
        </template>
        <ReportHeatmap
          :heat-data="accountConversationHeatmap"
          :is-loading="uiFlags.isFetchingAccountConversationsHeatmap"
        />
      </MetricCard>
    </div>
    <div class="flex flex-row flex-wrap max-w-full">
      <MetricCard :header="$t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.HEADER')">
        <AgentTable
          :agents="agents"
          :agent-metrics="agentConversationMetric"
          :page-index="pageIndex"
          :is-loading="uiFlags.isFetchingAgentConversationMetric"
          @page-change="onPageNumberChange"
        />
      </MetricCard>
    </div>
    <ConversationAnalytics />
    <Csat />
    <AgentReports />
  </div>
</template>
