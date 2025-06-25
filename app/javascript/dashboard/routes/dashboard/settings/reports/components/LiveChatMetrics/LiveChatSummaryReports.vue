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
      // Dummy data for live chat metrics
      dummyData: {
        sales: {
          pre_sales_queries: {
            working_hours: 234,
            non_working_hours: 45,
            total: 279,
          },
          total_orders: {
            working_hours: 156,
            non_working_hours: 23,
            total: 179,
          },
          revenue_generated: {
            working_hours: 12450.75,
            non_working_hours: 2969.25,
            total: 15420.0,
          },
        },
        support: {
          total_queries: {
            working_hours: 567,
            non_working_hours: 89,
            total: 656,
          },
          resolved: { working_hours: 498, non_working_hours: 67, total: 565 },
          avg_resolve_time: {
            working_hours: 420,
            non_working_hours: 680,
            total: 480,
          },
          handoff_to_agents: {
            working_hours: 69,
            non_working_hours: 22,
            total: 91,
          },
          avg_csat_score: {
            working_hours: 4.3,
            non_working_hours: 3.8,
            total: 4.2,
          },
        },
        others: {
          impression: {
            working_hours: 12450,
            non_working_hours: 2340,
            total: 14790,
          },
          widget_opened: {
            working_hours: 3456,
            non_working_hours: 678,
            total: 4134,
          },
          intent_match: {
            working_hours: 2890,
            non_working_hours: 456,
            total: 3346,
          },
          fallback_rate: {
            working_hours: 12.5,
            non_working_hours: 18.3,
            total: 14.2,
          },
        },
      },
    };
  },
  computed: {
    summaryData() {
      const titlesMapping = {
        // Sales Analytics metrics
        pre_sales_queries: 'Pre sales queries (csdb)',
        total_orders: 'Total Orders (multichannel)',
        revenue_generated: 'Revenue Generated (multichannel)',

        // Support Analytics metrics
        total_queries: 'Total Queries',
        resolved: 'Resolved',
        avg_resolve_time: 'Average Resolve Time',
        handoff_to_agents: 'Handoff to Agents',
        avg_csat_score: 'Avg CSAT score (csdb)',

        // Others metrics
        impression: 'Impression (multichannel)',
        widget_opened: 'Widget opened (multichannel)',
        intent_match: 'Intent Match (multichannel)',
        fallback_rate: 'Fall back rate',
      };

      // Determine which dataset to use based on the action key
      let dataType = 'performance';
      if (this.actionKey.includes('Sales')) {
        dataType = 'sales';
      } else if (this.actionKey.includes('Support')) {
        dataType = 'support';
      } else if (this.actionKey.includes('Others')) {
        dataType = 'others';
      }

      const groupedData = this.dummyData[dataType];

      if (!groupedData || Object.keys(groupedData).length === 0) {
        return [];
      }

      const result = [];
      Object.keys(groupedData).forEach(key => {
        const workingHours = groupedData[key]?.working_hours || 0;
        const nonWorkingHours = groupedData[key]?.non_working_hours || 0;
        const total = groupedData[key]?.total || 0;

        result.push({
          title: titlesMapping[key],
          outOfOffice: this.renderContent(key, nonWorkingHours, total),
          workHours: this.renderContent(key, workingHours, total),
          total: this.renderContent(key, total, total),
        });
      });

      return result;
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    renderContent(key, value) {
      const timeMetrics = ['avg_resolve_time'];
      const financeMetrics = ['revenue_generated'];
      const percentageMetrics = [
        'fallback_rate',
        'resolved',
        'handoff_to_agents',
      ];
      const ratingMetrics = ['avg_csat_score'];

      // Use USD as default currency
      const currencySymbol = '$';

      let displayValue;
      if (timeMetrics.includes(key)) {
        displayValue = value ? formatTime(value) : '--';
      } else if (financeMetrics.includes(key)) {
        displayValue = value
          ? `${currencySymbol}${value.toLocaleString()}`
          : '--';
      } else if (percentageMetrics.includes(key)) {
        displayValue = value ? `${value}%` : '--';
      } else if (ratingMetrics.includes(key)) {
        displayValue = value ? `${value}/5.0` : '--';
      } else {
        displayValue = value;
      }

      return displayValue;
    },
    async fetchAllData() {
      if (this.isFetchingData) return;

      this.isFetchingData = true;
      const { from, to } = this;
      this.emitFilterChange();

      try {
        // Simulate API call delay
        await new Promise(resolve => {
          setTimeout(resolve, 800);
        });

        // Update dummy data with some variation based on time range
        const daysDiff = Math.floor((to - from) / (24 * 60 * 60));
        const multiplier = Math.max(0.5, Math.min(2, daysDiff / 7));

        // Update sales data
        Object.keys(this.dummyData.sales).forEach(key => {
          if (key === 'revenue_generated') {
            this.dummyData.sales[key].working_hours = Math.floor(
              this.dummyData.sales[key].working_hours *
                multiplier *
                (0.9 + Math.random() * 0.2)
            );
            this.dummyData.sales[key].non_working_hours = Math.floor(
              this.dummyData.sales[key].non_working_hours *
                multiplier *
                (0.8 + Math.random() * 0.4)
            );
            this.dummyData.sales[key].total = Math.floor(
              this.dummyData.sales[key].total *
                multiplier *
                (0.85 + Math.random() * 0.3)
            );
          } else {
            this.dummyData.sales[key].working_hours = Math.floor(
              this.dummyData.sales[key].working_hours *
                multiplier *
                (0.9 + Math.random() * 0.2)
            );
            this.dummyData.sales[key].non_working_hours = Math.floor(
              this.dummyData.sales[key].non_working_hours *
                multiplier *
                (0.8 + Math.random() * 0.4)
            );
            this.dummyData.sales[key].total = Math.floor(
              this.dummyData.sales[key].total *
                multiplier *
                (0.85 + Math.random() * 0.3)
            );
          }
        });

        // Update support data
        Object.keys(this.dummyData.support).forEach(key => {
          if (key === 'avg_resolve_time') {
            this.dummyData.support[key].working_hours = Math.floor(
              this.dummyData.support[key].working_hours *
                multiplier *
                (0.9 + Math.random() * 0.2)
            );
            this.dummyData.support[key].non_working_hours = Math.floor(
              this.dummyData.support[key].non_working_hours *
                multiplier *
                (0.8 + Math.random() * 0.4)
            );
            this.dummyData.support[key].total = Math.floor(
              this.dummyData.support[key].total *
                multiplier *
                (0.85 + Math.random() * 0.3)
            );
          } else if (key === 'avg_csat_score') {
            this.dummyData.support[key].working_hours =
              Math.round(
                this.dummyData.support[key].working_hours *
                  multiplier *
                  (0.9 + Math.random() * 0.2) *
                  10
              ) / 10;
            this.dummyData.support[key].non_working_hours =
              Math.round(
                this.dummyData.support[key].non_working_hours *
                  multiplier *
                  (0.8 + Math.random() * 0.4) *
                  10
              ) / 10;
            this.dummyData.support[key].total =
              Math.round(
                this.dummyData.support[key].total *
                  multiplier *
                  (0.85 + Math.random() * 0.3) *
                  10
              ) / 10;
          } else {
            this.dummyData.support[key].working_hours = Math.floor(
              this.dummyData.support[key].working_hours *
                multiplier *
                (0.9 + Math.random() * 0.2)
            );
            this.dummyData.support[key].non_working_hours = Math.floor(
              this.dummyData.support[key].non_working_hours *
                multiplier *
                (0.8 + Math.random() * 0.4)
            );
            this.dummyData.support[key].total = Math.floor(
              this.dummyData.support[key].total *
                multiplier *
                (0.85 + Math.random() * 0.3)
            );
          }
        });

        // Update others data
        Object.keys(this.dummyData.others).forEach(key => {
          if (key === 'fallback_rate') {
            this.dummyData.others[key].working_hours =
              Math.round(
                this.dummyData.others[key].working_hours *
                  multiplier *
                  (0.9 + Math.random() * 0.2) *
                  10
              ) / 10;
            this.dummyData.others[key].non_working_hours =
              Math.round(
                this.dummyData.others[key].non_working_hours *
                  multiplier *
                  (0.8 + Math.random() * 0.4) *
                  10
              ) / 10;
            this.dummyData.others[key].total =
              Math.round(
                this.dummyData.others[key].total *
                  multiplier *
                  (0.85 + Math.random() * 0.3) *
                  10
              ) / 10;
          } else {
            this.dummyData.others[key].working_hours = Math.floor(
              this.dummyData.others[key].working_hours *
                multiplier *
                (0.9 + Math.random() * 0.2)
            );
            this.dummyData.others[key].non_working_hours = Math.floor(
              this.dummyData.others[key].non_working_hours *
                multiplier *
                (0.8 + Math.random() * 0.4)
            );
            this.dummyData.others[key].total = Math.floor(
              this.dummyData.others[key].total *
                multiplier *
                (0.85 + Math.random() * 0.3)
            );
          }
        });
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
    onFilterChange({ from, to }) {
      this.from = from;
      this.to = to;
      this.fetchAllData();
    },
    downloadReports() {
      // Simulate download functionality
      this.showAlert('Report download initiated!');
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
