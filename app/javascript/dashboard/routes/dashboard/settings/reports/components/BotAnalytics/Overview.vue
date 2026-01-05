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
      selectedFlow: null,
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
      const currencySymbol = getSymbolFromCurrency(
        this.$store.getters['summaryReports/getCurrency'] || 'INR'
      );
      Object.keys(this.botConversationMetric).forEach(key => {
        if (key === 'grouped_data') {
          return;
        }
        const metricNames = {
          bot_total_revenue: 'Total Revenue Generated',
          sales_ooo_hours: 'Sales generated during OOO hours',
          bot_resolved: 'Total Queries Resolved',
        };
        const metricName = metricNames[key] || '';
        metric[metricName] =
          key === 'bot_total_revenue'
            ? `${currencySymbol}${(
                this.botConversationMetric[key] || 0
              ).toFixed(2)}`
            : this.botConversationMetric[key] || 0;
      });
      return metric;
    },
    teamsList() {
      return [noneTeam, ...this.teams];
    },
  },
  methods: {
    onFilterChange({ from, to, selectedFlow }) {
      const flowChanged =
        this.selectedFlow?.id !== selectedFlow?.id ||
        (!this.selectedFlow && selectedFlow) ||
        (this.selectedFlow && !selectedFlow);

      if (this.from !== from || this.to !== to || flowChanged) {
        this.from = from;
        this.to = to;
        this.selectedFlow = selectedFlow;
        this.fetchAllData();
      }
    },
    async fetchAllData() {
      if (this.isFetchingData) return;

      this.isFetchingData = true;
      try {
        const params = {
          since: this.from,
          until: this.to,
        };

        // Add flowId if a specific flow is selected
        if (this.selectedFlow && this.selectedFlow.id) {
          params.flowId = this.selectedFlow.id;
        }

        await this.$store.dispatch('fetchBotConversationMetric', params);
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
          :show-flow-filter="true"
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
          <spinner
            color-scheme="before:!border-slate-600 before:!border-t-slate-400 dark:before:!border-slate-400 dark:before:!border-t-slate-200"
          />
          <span class="text-slate-600 dark:text-slate-200 ml-2">
            Loading metrics
          </span>
        </div>
      </div>
    </metric-card>
  </div>
</template>
