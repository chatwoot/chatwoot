<template>
  <div class="flex-1 p-4 overflow-auto">
    <report-filter-selector
      :show-agents-filter="false"
      :show-group-by-filter="true"
      :show-business-hours-switch="false"
      @filter-change="onFilterChange"
    />

    <bot-metrics :filters="requestPayload" />
    <report-container
      :group-by="groupBy"
      :report-keys="reportKeys"
      :account-summary-key="'getBotSummary'"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import BotMetrics from './components/BotMetrics.vue';
import ReportFilterSelector from './components/FilterSelector.vue';
import { GROUP_BY_FILTER } from './constants';
import reportMixin from 'dashboard/mixins/reportMixin';
import ReportContainer from './ReportContainer.vue';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  name: 'BotReports',
  components: {
    BotMetrics,
    ReportFilterSelector,
    ReportContainer,
  },
  mixins: [reportMixin],
  data() {
    return {
      from: 0,
      to: 0,
      groupBy: GROUP_BY_FILTER[1],
      reportKeys: {
        BOT_RESOLUTION_COUNT: 'bot_resolutions_count',
        BOT_HANDOFF_COUNT: 'bot_handoffs_count',
      },
      businessHours: false,
    };
  },
  computed: {
    ...mapGetters({
      accountReport: 'getAccountReports',
    }),
    requestPayload() {
      return {
        from: this.from,
        to: this.to,
      };
    },
  },
  methods: {
    fetchAllData() {
      this.fetchBotSummary();
      this.fetchChartData();
    },
    fetchBotSummary() {
      try {
        this.$store.dispatch('fetchBotSummary', this.getRequestPayload());
      } catch {
        useAlert(this.$t('REPORT.SUMMARY_FETCHING_FAILED'));
      }
    },
    fetchChartData() {
      Object.keys(this.reportKeys).forEach(async key => {
        try {
          await this.$store.dispatch('fetchAccountReport', {
            metric: this.reportKeys[key],
            ...this.getRequestPayload(),
          });
        } catch {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    getRequestPayload() {
      const { from, to, groupBy, businessHours } = this;

      return {
        from,
        to,
        groupBy: groupBy?.period,
        businessHours,
      };
    },
    onFilterChange({ from, to, groupBy, businessHours }) {
      this.from = from;
      this.to = to;
      this.groupBy = groupBy;
      this.businessHours = businessHours;
      this.fetchAllData();

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterValue: { from, to, groupBy, businessHours },
        reportType: 'bots',
      });
    },
  },
};
</script>
