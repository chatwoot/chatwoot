<template>
  <div class="flex-1 overflow-auto p-4">
    <woot-button
      v-if="showDownloadButton"
      color-scheme="success"
      class-names="button--fixed-top"
      icon="arrow-download"
      @click="downloadReports"
    >
      {{ downloadButtonLabel }}
    </woot-button>
    <report-filter-selector
      :key="`filter-selector-${type}`"
      :show-agents-filter="false"
      :show-labels-filter="showAdvancedFilters"
      :show-inbox-filter="false"
      :show-business-hours-switch="false"
      @filter-change="onFilterChange"
    />
    <div v-if="!isFetchingData" class="summary-cards">
      <div
        v-for="(card, index) in summaryData"
        :key="index"
        class="summary-card border border-[#eaecf0] dark:border-[#4C5155]"
      >
        <h3 class="text-sm font-medium mb-4">{{ card.title }}</h3>
        <div class="summary-item">
          <span>Out of Office</span>
          <span class="text-sm">{{ card.outOfOffice }}</span>
        </div>
        <div class="summary-item">
          <span>Work Hours</span>
          <span class="text-sm">{{ card.workHours }}</span>
        </div>
        <div
          class="summary-total border-t border-[#eaecf0] dark:border-[#4C5155]"
        >
          <span class="text-xs">Total</span>
          <span class="text-lg font-bold">{{ card.total }}</span>
        </div>
      </div>
    </div>
    <div v-else class="items-center flex text-base justify-center px-12 py-6">
      <spinner />
      <span class="text-slate-300 dark:text-slate-200 ml-2">
        Loading metrics
      </span>
    </div>
  </div>
</template>

<script>
import ReportFilterSelector from './../FilterSelector.vue';
import { formatTime } from '@chatwoot/utils';
import Spinner from 'shared/components/Spinner.vue';
import reportMixin from './../../../../../../mixins/reportMixin';
import alertMixin from 'shared/mixins/alertMixin';
import getSymbolFromCurrency from 'currency-symbol-map';

export default {
  components: {
    ReportFilterSelector,
    Spinner,
  },
  mixins: [reportMixin, alertMixin],
  props: {
    type: {
      type: String,
      default: 'account',
    },
    actionKey: {
      type: String,
      default: '',
    },
    summaryKey: {
      type: String,
      default: '',
    },
    downloadButtonLabel: {
      type: String,
      default: 'Download Reports',
    },
    showDownloadButton: {
      type: Boolean,
      default: false,
    },
    showAdvancedFilters: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    const today = new Date();
    const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);

    return {
      from: sevenDaysAgo.getTime() / 1000, // Unix timestamp in seconds
      to: today.getTime() / 1000, // Unix timestamp in seconds
      selectedFilter: null,
      selectedMetricType: 'Average',
      isFetchingData: false,
    };
  },
  computed: {
    summaryData() {
      const titlesMapping = {
        bot_handled: 'Total Queries',
        bot_resolved: 'Resolved',
        bot_avg_resolution_time: 'Average Resolve Time',
        bot_assign_to_agent: 'Handoff to Agents',
        pre_sale_queries: 'Pre-sales Queries',
        bot_orders_placed: 'Total Orders',
        bot_revenue_generated: 'Revenue Generated',
      };

      const getter = this.$store.getters[this.summaryKey];

      // Safely access nested data
      const data = getter?.data || {};

      const groupedData = data.grouped_data || {};

      if (!groupedData || Object.keys(groupedData).length === 0) {
        return [];
      }

      const result = [];
      Object.keys(groupedData).forEach(key => {
        if (key === 'grouped_by') return;

        // Add safety checks for data access
        const workingHours = groupedData[key]?.working_hours || 0;
        const nonWorkingHours = groupedData[key]?.non_working_hours || 0;
        let workingTotal = groupedData.bot_handled?.working_hours || 0;
        let nonWorkingTotal = groupedData.bot_handled?.non_working_hours || 0;

        if (key === 'bot_orders_placed') {
          workingTotal = groupedData.pre_sale_queries?.working_hours || 0;
          nonWorkingTotal =
            groupedData.pre_sale_queries?.non_working_hours || 0;
        }

        const totalBotHandled = workingTotal + nonWorkingTotal;

        // TODO: fix total value for avg resolution time
        const totalValue =
          key === 'bot_avg_resolution_time'
            ? groupedData[key]?.total || 0
            : workingHours + nonWorkingHours;

        result.push({
          title: titlesMapping[key],
          outOfOffice: this.renderContent(
            key,
            nonWorkingHours,
            nonWorkingTotal
          ),
          workHours: this.renderContent(key, workingHours, workingTotal),
          total: this.renderContent(key, totalValue, totalBotHandled),
        });
      });

      return result;
    },
  },
  mounted() {
    this.fetchAllData();
    this.$store.dispatch('labels/get', { force: true });
  },
  methods: {
    renderContent(key, value, total) {
      const timeMetrics = ['bot_avg_resolution_time'];
      const financeMetrics = ['bot_revenue_generated'];
      const currencySymbol = getSymbolFromCurrency(
        this.$store.getters['summaryReports/getCurrency'] || 'INR'
      );

      const percentageMetrics = [
        'bot_resolved',
        'bot_assign_to_agent',
        'bot_orders_placed',
      ];

      let displayValue;
      if (timeMetrics.includes(key)) {
        displayValue = value ? formatTime(value) : '--';
      } else if (financeMetrics.includes(key)) {
        displayValue = value ? `${currencySymbol}${value.toFixed(2)}` : '--';
      } else {
        displayValue = value;
      }

      // Add percentage if total is provided and value is not null/undefined
      if (total && value && percentageMetrics.includes(key)) {
        const percentage = ((value / total) * 100).toFixed(1);
        return `${displayValue} (${percentage}%)`;
      }

      return displayValue;
    },
    async fetchAllData() {
      if (this.isFetchingData) return;

      this.isFetchingData = true;
      const { from, to, selectedLabel } = this;
      this.emitFilterChange();

      try {
        await Promise.all([
          this.$store.dispatch('summaryReports/fetchCurrency'),
          this.$store.dispatch(this.actionKey, {
            since: from,
            until: to,
            selectedLabel,
          }),
        ]);
      } finally {
        this.isFetchingData = false;
      }
    },
    emitFilterChange() {
      this.$emit('filter-change', {
        since: this.from,
        until: this.to,
        selectedLabel: this.selectedLabel,
      });
    },
    onFilterChange({ from, to, selectedLabel }) {
      this.from = from;
      this.to = to;
      this.selectedLabel = selectedLabel;
      this.fetchAllData();
    },
  },
};
</script>

<style scoped>
.summary-cards {
  display: flex;
  justify-content: space-between;
  gap: 16px;
}
.summary-card {
  padding: 16px;
  border-radius: 8px;
  width: 100%;
}
.summary-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 4px 0;
  font-size: 12px;
}
.summary-total {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
  padding-top: 8px;
}
</style>
