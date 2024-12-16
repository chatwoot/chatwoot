<template>
  <div class="flex-1 overflow-auto p-4 pb-60">
    <div class="flex flex-col md:flex-row items-center">
      <div class="flex-1 w-full max-w-full conversation-metric">
        <overview />
      </div>
    </div>
    <div class="max-w-full flex flex-wrap flex-row ml-auto mr-auto">
      <metric-card
        :is-live="false"
        header="Sales Analytics"
        :show-download-button="true"
        :download-filters="salesFilters"
        :download-type="'botAnalyticsSalesOverview'"
      >
        <bot-summary-reports
          key="sales-summary-reports"
          class="!p-0"
          action-key="summaryReports/fetchCustomBotAnalyticsSalesOverviewReports"
          summary-key="summaryReports/getCustomBotAnalyticsSalesOverviewReports"
          @filter-change="handleSalesFilterChange"
        />
      </metric-card>
    </div>
    <div class="max-w-full flex flex-wrap flex-row ml-auto mr-auto">
      <metric-card
        :is-live="false"
        header="Support Analytics"
        :show-download-button="true"
        :download-filters="supportFilters"
        :download-type="'botAnalyticsSupportOverview'"
      >
        <bot-summary-reports
          key="support-summary-reports"
          class="!p-0"
          action-key="summaryReports/fetchCustomBotAnalyticsSupportOverviewReports"
          summary-key="summaryReports/getCustomBotAnalyticsSupportOverviewReports"
          :show-advanced-filters="true"
          @filter-change="handleSupportFilterChange"
        />
      </metric-card>
    </div>
  </div>
</template>
<script>
import Overview from './components/BotAnalytics/Overview.vue';
import MetricCard from './components/overview/MetricCard.vue';
import BotSummaryReports from './components/BotAnalytics/BotSummaryReports.vue';
import { mapGetters } from 'vuex';

export default {
  name: 'LiveReports',
  components: {
    Overview,
    MetricCard,
    BotSummaryReports,
  },
  data() {
    return {
      salesFilters: {},
      supportFilters: {},
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
  },
};
</script>
