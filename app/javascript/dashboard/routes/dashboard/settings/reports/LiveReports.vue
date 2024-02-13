<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="row">
      <open-conversations />

      <div class="column small-12 medium-4 flex">
        <metric-card
          :header="$t('OVERVIEW_REPORTS.AGENT_STATUS.HEADER')"
          class="flex-1"
        >
          <div
            v-for="(metric, name, index) in agentStatusMetrics"
            :key="index"
            class="metric-content column"
          >
            <h3 class="heading">
              {{ name }}
            </h3>
            <p class="metric">{{ metric }}</p>
          </div>
        </metric-card>
      </div>
    </div>
    <div class="row">
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
    <div class="row">
      <metric-card :header="$t('OVERVIEW_REPORTS.AGENT_CONVERSATIONS.HEADER')">
        <agent-table
          :agents="agents"
          :agent-metrics="agentConversationMetric"
          :page-index="pageIndex"
          :is-loading="uiFlags.isFetchingAgentConversationMetric"
        />
      </metric-card>
    </div>
    <div class="row">
      <metric-card :header="$t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.HEADER')">
        <team-table
          :teams="teams"
          :team-metrics="teamConversationMetric"
          :page-index="pageIndex"
          :is-loading="uiFlags.isFetchingTeamConversationMetric"
        />
      </metric-card>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import OpenConversations from './components/LiveReports/OpenConversations.vue';
import AgentTable from './components/overview/AgentTable.vue';
import TeamTable from './components/overview/TeamTable.vue';
import MetricCard from './components/overview/MetricCard.vue';
import ReportHeatmap from './components/Heatmap.vue';

import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import { OVERVIEW_METRICS } from './constants';

export default {
  name: 'LiveReports',
  components: {
    OpenConversations,
    TeamTable,
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
      teams: 'teams/getTeams',
      agentConversationMetric: 'getAgentConversationMetric',
      teamConversationMetric: 'getTeamConversationMetric',
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
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('teams/get');
    this.fetchAllData();

    bus.$on('fetch_overview_reports', () => {
      this.fetchAllData();
    });
  },
  methods: {
    fetchAllData() {
      this.$store.dispatch('fetchAgentConversationMetric');
      this.$store.dispatch('fetchTeamConversationMetric');
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
  },
};
</script>
