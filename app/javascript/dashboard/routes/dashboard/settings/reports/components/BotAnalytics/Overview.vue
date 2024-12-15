<script>
import { mapGetters } from 'vuex';
import MetricCard from '../overview/MetricCard.vue';
import ReportFilterSelector from './../FilterSelector.vue';
import Spinner from 'shared/components/Spinner.vue';
const noneTeam = { team_id: 0, name: 'All teams' };

export default {
  components: {
    ReportFilterSelector,
    MetricCard,
    Spinner,
  },
  data() {
    return {
      selectedTeam: noneTeam,
      isFetchingData: false,
      from: 0,
      to: 0,
    };
  },
  computed: {
    ...mapGetters({
      teams: 'teams/getTeams',
      botConversationMetric: 'getBotConversationMetric',
      uiFlags: 'getOverviewUIFlags',
    }),
    conversationMetrics() {
      let metric = {};
      Object.keys(this.botConversationMetric).forEach(key => {
        if (key === 'grouped_data') {
          return;
        }
        const metricNames = {
          bot_total_revenue: 'Total Revenue Generated',
          sales_ooo_hours: 'Sales generated during OOO hours',
          bot_handled: 'Total Queries Automated',
        };
        const metricName = metricNames[key] || '';
        metric[metricName] =
          key === 'bot_total_revenue'
            ? `₹${(this.botConversationMetric[key] || 0).toFixed(2)}`
            : this.botConversationMetric[key] || 0;
      });
      return metric;
    },
    teamsList() {
      return [noneTeam, ...this.teams];
    },
  },
  methods: {
    onFilterChange({ from, to }) {
      if (this.from !== from || this.to !== to) {
        this.from = from;
        this.to = to;
        this.fetchAllData();
      }
    },
    async fetchAllData() {
      if (this.isFetchingData) return;

      this.isFetchingData = true;
      try {
        await this.$store.dispatch('fetchBotConversationMetric', {
          since: this.from,
          until: this.to,
        });
      } finally {
        this.isFetchingData = false;
      }
    },
  },
};
</script>

<template>
  <div class="column small-12 medium-8 conversation-metric">
    <metric-card
      class="overflow-visible min-h-[150px]"
      :header="'Overview'"
      :is-live="false"
    >
      <div class="flex-1 overflow-auto w-full">
        <report-filter-selector
          :key="`filter-selector-overview`"
          :show-agents-filter="false"
          :show-labels-filter="false"
          :show-inbox-filter="false"
          :show-business-hours-switch="false"
          @filter-change="onFilterChange"
        />
        <div
          v-if="!uiFlags.isFetchingBotConversationMetric"
          class="flex justify-between border border-[#eaecf0] dark:border-[#4C5155] rounded-lg p-4"
        >
          <div
            v-for="(metric, name, index) in conversationMetrics"
            :key="index"
            class="metric-content column"
          >
            <h3 class="heading">
              {{ name }}
            </h3>
            <p class="metric">{{ metric }}</p>
          </div>
        </div>
        <div
          v-else
          class="items-center flex text-base justify-center px-12 py-6"
        >
          <spinner />
          <span class="text-slate-300 dark:text-slate-200 ml-2">
            Loading metrics
          </span>
        </div>
      </div>
    </metric-card>
  </div>
</template>
