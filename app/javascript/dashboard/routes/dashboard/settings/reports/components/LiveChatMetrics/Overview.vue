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
      // Dummy data for overview metrics
      overviewMetrics: {
        total_revenue_generated: 15420.5,
        sales_ooo_hours: 3240.75,
        total_queries_resolved: 892,
      },
    };
  },
  computed: {
    ...mapGetters({
      teams: 'teams/getTeams',
      uiFlags: 'getOverviewUIFlags',
    }),
    conversationMetrics() {
      const currencySymbol = getSymbolFromCurrency(
        this.$store.getters['summaryReports/getCurrency'] || 'USD'
      );

      const metrics = {
        'Total Revenue Generated (multichannel)': `${currencySymbol}${this.overviewMetrics.total_revenue_generated.toLocaleString()}`,
        'Sales generated during OOO hours (multichannel)': `${currencySymbol}${this.overviewMetrics.sales_ooo_hours.toLocaleString()}`,
        'Total Queries Resolved (csdb)':
          this.overviewMetrics.total_queries_resolved,
      };
      return metrics;
    },
    teamsList() {
      return [noneTeam, ...this.teams];
    },
  },
  mounted() {
    // Set default date range to last 7 days
    const today = new Date();
    const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    this.from = sevenDaysAgo.getTime() / 1000;
    this.to = today.getTime() / 1000;
    this.fetchAllData();
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
        // Simulate API call delay
        await new Promise(resolve => {
          setTimeout(resolve, 1000);
        });

        // Update dummy data with some variation based on time range
        const daysDiff = Math.floor((this.to - this.from) / (24 * 60 * 60));
        const multiplier = Math.max(0.5, Math.min(2, daysDiff / 7));

        this.overviewMetrics = {
          total_revenue_generated: Math.floor(
            15420.5 * multiplier * (0.9 + Math.random() * 0.2)
          ),
          sales_ooo_hours: Math.floor(
            3240.75 * multiplier * (0.8 + Math.random() * 0.4)
          ),
          total_queries_resolved: Math.floor(
            892 * multiplier * (0.85 + Math.random() * 0.3)
          ),
        };
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
          v-if="!isFetchingData"
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
