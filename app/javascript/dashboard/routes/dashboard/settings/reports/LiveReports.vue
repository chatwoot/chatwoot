<template>
  <div class="flex-1 overflow-auto p-4">
    <div class="flex flex-col md:flex-row items-center">
      <div
        class="flex-1 w-full max-w-full md:w-[65%] md:max-w-[65%] conversation-metric"
      >
        <open-conversations />
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
      <metric-card
        :custom-class="isCustomDateRange ? '!mb-[8rem]' : ''"
        :header="$t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.HEADER')"
      >
        <template #control>
          <div class="flex gap-2 items-center">
            <multiselect-dropdown
              class="!mb-0 !w-auto min-w-[160px]"
              :options="dayFilterOptions"
              :selected-item="selectedDayFilter"
              multiselector-title=""
              multiselector-placeholder="Date filter"
              no-search-result="No filter found"
              input-placeholder="Search for a filter"
              :is-filter="true"
              :has-thumbnail="false"
              @click="onSelectDateFilter"
            />
            <div class="custom-date-range">
              <woot-date-range-picker
                v-if="isCustomDateRange"
                show-range
                class="!mb-[-1rem]"
                :value="customDateRange"
                :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
                :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
                @change="onCustomDateRangeChange"
              />
            </div>
            <woot-button
              icon="arrow-download"
              size="small"
              variant="smooth"
              color-scheme="secondary"
              @click="downloadHeatmapData"
            >
              Download Report
            </woot-button>
          </div>
        </template>
        <report-heatmap
          :selected-day-filter="selectedDayFilter"
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
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';

import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import { OVERVIEW_METRICS } from './constants';

const dayFilterOptions = [
  {
    id: 1,
    name: 'Last 7 days',
  },
  {
    id: 2,
    name: 'Last 30 days',
  },
  {
    id: 3,
    name: 'Custom date range',
  },
];

export default {
  name: 'LiveReports',
  components: {
    OpenConversations,
    TeamTable,
    AgentTable,
    MetricCard,
    ReportHeatmap,
    MultiselectDropdown,
    WootDateRangePicker,
  },
  data() {
    return {
      pageIndex: 1,
      dayFilterOptions: dayFilterOptions,
      selectedDayFilter: dayFilterOptions[0],
      customDateRange: [new Date(), new Date()],
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
    isCustomDateRange() {
      return this.selectedDayFilter?.id === 3;
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('teams/get');
    this.fetchAllData();

    this.$emitter.on('fetch_overview_reports', () => {
      this.fetchAllData();
    });
  },
  methods: {
    onSelectDateFilter(dayFilter) {
      this.selectedDayFilter = dayFilter;
      if (!this.isCustomDateRange) {
        this.fetchHeatmapData();
      }
    },
    onCustomDateRangeChange(value) {
      this.customDateRange = value;
      this.fetchHeatmapData();
    },
    fetchAllData() {
      this.$store.dispatch('fetchAgentConversationMetric');
      this.$store.dispatch('fetchTeamConversationMetric');
      this.fetchHeatmapData();
    },
    downloadHeatmapData() {
      let to;
      let daysBefore;

      if (this.isCustomDateRange) {
        to = endOfDay(this.customDateRange[1]);
        const from = startOfDay(this.customDateRange[0]);
        const diffInDays = Math.ceil((to - from) / (1000 * 60 * 60 * 24));
        daysBefore = diffInDays - 1;
      } else {
        to = endOfDay(new Date());
        daysBefore = this.selectedDayFilter?.id === 1 ? 6 : 29;
      }

      this.$store.dispatch('downloadAccountConversationHeatmap', {
        daysBefore: daysBefore,
        to: getUnixTime(to),
      });
    },

    fetchHeatmapData() {
      if (this.uiFlags.isFetchingAccountConversationsHeatmap) {
        return;
      }

      let to;
      let from;

      if (this.isCustomDateRange) {
        to = endOfDay(this.customDateRange[1]);
        from = startOfDay(this.customDateRange[0]);
      } else {
        // the data for the last 6 days won't ever change,
        // so there's no need to fetch it again
        // but we can write some logic to check if the data is already there
        // if it is there, we can refetch data only for today all over again
        // and reconcile it with the rest of the data
        // this will reduce the load on the server doing number crunching
        to = endOfDay(new Date());
        from = startOfDay(
          subDays(to, this.selectedDayFilter?.id === 1 ? 6 : 29)
        );
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
