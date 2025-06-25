<template>
  <div class="flex-1 overflow-auto p-4 pb-60">
    <!-- Overview Section -->
    <div class="mb-8">
      <div class="flex flex-col md:flex-row items-center">
        <div class="flex-1 w-full max-w-full conversation-metric">
          <overview />
        </div>
      </div>
    </div>

    <!-- Sales Analytics Section -->
    <div class="mb-8">
      <metric-card
        :is-live="false"
        header="Sales Analytics"
        :show-download-button="true"
        :download-filters="salesFilters"
        :download-type="'liveChatSalesOverview'"
      >
        <live-chat-summary-reports
          key="sales-summary-reports"
          class="!p-0"
          action-key="summaryReports/fetchCustomLiveChatSalesOverviewReports"
          summary-key="summaryReports/getCustomLiveChatSalesOverviewReports"
          @filter-change="handleSalesFilterChange"
        />
      </metric-card>
    </div>

    <!-- Support Analytics Section -->
    <div class="mb-8">
      <metric-card
        :is-live="false"
        header="Support Analytics"
        :show-download-button="true"
        :download-filters="supportFilters"
        :download-type="'liveChatSupportOverview'"
      >
        <live-chat-summary-reports
          key="support-summary-reports"
          class="!p-0"
          action-key="summaryReports/fetchCustomLiveChatSupportOverviewReports"
          summary-key="summaryReports/getCustomLiveChatSupportOverviewReports"
          :show-advanced-filters="true"
          @filter-change="handleSupportFilterChange"
        />
      </metric-card>
    </div>

    <!-- Others Section -->
    <div class="mb-8">
      <metric-card
        :is-live="false"
        header="Others"
        :show-download-button="true"
        :download-filters="othersFilters"
        :download-type="'liveChatOthersOverview'"
      >
        <live-chat-summary-reports
          key="others-summary-reports"
          class="!p-0"
          action-key="summaryReports/fetchCustomLiveChatOthersOverviewReports"
          summary-key="summaryReports/getCustomLiveChatOthersOverviewReports"
          :show-advanced-filters="true"
          @filter-change="handleOthersFilterChange"
        />
      </metric-card>
    </div>
  </div>
</template>
<script>
import Overview from './components/LiveChatMetrics/Overview.vue';
import MetricCard from './components/overview/MetricCard.vue';
import LiveChatSummaryReports from './components/LiveChatMetrics/LiveChatSummaryReports.vue';
import { mapGetters } from 'vuex';

export default {
  name: 'LiveChatMetrics',
  components: {
    Overview,
    MetricCard,
    LiveChatSummaryReports,
  },
  data() {
    return {
      salesFilters: {},
      supportFilters: {},
      othersFilters: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'summaryReports/getUiFlags',
    }),
  },
  methods: {
    handleSalesFilterChange(filter) {
      this.salesFilters = filter;
    },
    handleSupportFilterChange(filter) {
      this.supportFilters = filter;
    },
    handleOthersFilterChange(filter) {
      this.othersFilters = filter;
    },
  },
};
</script>
