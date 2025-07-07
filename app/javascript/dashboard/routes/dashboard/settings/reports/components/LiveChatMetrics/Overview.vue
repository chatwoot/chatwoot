<script>
import { mapGetters } from 'vuex';
import MetricCard from '../overview/MetricCard.vue';
import ReportFilterSelector from './../FilterSelector.vue';
import Spinner from 'shared/components/Spinner.vue';
import getSymbolFromCurrency from 'currency-symbol-map';

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
      uiFlags: 'getOverviewUIFlags',
      liveChatConversationMetric: 'getLiveChatConversationMetric',
    }),
    conversationMetrics() {
      let metric = {};
      const currencySymbol = getSymbolFromCurrency(
        this.$store.getters['summaryReports/getLiveChatCurrency'] || 'INR'
      );

      Object.keys(this.liveChatConversationMetric).forEach(key => {
        if (key === 'grouped_data') {
          return;
        }
        const metricNames = {
          live_chat_total_revenue: 'Total Revenue Generated',
          live_chat_sales_ooo_hours: 'Sales generated during OOO hours',
          bot_resolved: 'Total Queries Resolved',
        };
        const metricName = metricNames[key] || '';
        metric[metricName] =
          key === 'live_chat_total_revenue'
            ? `${currencySymbol}${(
                this.liveChatConversationMetric[key] || 0
              ).toFixed(2)}`
            : this.liveChatConversationMetric[key] || 0;
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
        await this.$store.dispatch('fetchLiveChatConversationMetric', {
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
          v-if="!uiFlags.isFetchingLiveChatConversationMetric"
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

<style scoped>
.metric-content {
  text-align: center;
  padding: 0 8px;
}

.heading {
  font-size: 12px;
  color: #6b7280;
  margin-bottom: 4px;
  font-weight: 500;
}

.metric {
  font-size: 18px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.dark .metric {
  color: #f9fafb;
}
</style>
