<template>
  <div class="flex-1 overflow-auto p-4">
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
      <metric-card :header="$t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.HEADER')">
        <template #control>
          <woot-button
            icon="arrow-download"
            size="small"
            variant="smooth"
            color-scheme="secondary"
            @click="downloadHeatmapData"
          >
            Download Report
          </woot-button>
        </template>
        <report-heatmap
          :heat-data="accountConversationHeatmap"
          :is-loading="uiFlags.isFetchingAccountConversationsHeatmap"
        />
      </metric-card>
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
import ReportHeatmap from './components/Heatmap.vue';

import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';

export default {
  name: 'LiveReports',
  components: {
    AgentTable,
    MetricCard,
    ReportHeatmap,
  },
  data() {
    return {
      pageIndex: 1,
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

    this.$emitter.on('fetch_overview_reports', () => {
      this.fetchAllData();
    });
  },
  methods: {
    fetchAllData() {
      this.fetchAccountConversationMetric();
      this.fetchAgentConversationMetric();
      this.fetchHeatmapData();
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
        page: this.pageIndex,
      });
    },
    onPageNumberChange(pageIndex) {
      this.pageIndex = pageIndex;
      this.fetchAgentConversationMetric();
    },
  },
};
</script>
