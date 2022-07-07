import { mapGetters } from 'vuex';
import { formatTime } from '@chatwoot/utils';

export default {
  computed: {
    ...mapGetters({
      accountSummary: 'getAccountSummary',
      accountReport: 'getAccountReports',
    }),
    calculateTrend() {
      return metric_key => {
        if (!this.accountSummary.previous[metric_key]) return 0;
        return Math.round(
          ((this.accountSummary[metric_key] -
            this.accountSummary.previous[metric_key]) /
            this.accountSummary.previous[metric_key]) *
            100
        );
      };
    },
    displayMetric() {
      return metric_key => {
        if (this.isAverageMetricType(metric_key)) {
          return formatTime(this.accountSummary[metric_key]);
        }
        return this.accountSummary[metric_key];
      };
    },
    displayInfoText() {
      return metric_key => {
        if (this.metrics[this.currentSelection].KEY !== metric_key) {
          return '';
        }
        if (this.isAverageMetricType(metric_key)) {
          const total = this.accountReport.data
            .map(item => item.count)
            .reduce((prev, curr) => prev + curr, 0);
          return `${this.metrics[this.currentSelection].INFO_TEXT} ${total}`;
        }
        return '';
      };
    },
    isAverageMetricType() {
      return metric_key => {
        return ['avg_first_response_time', 'avg_resolution_time'].includes(
          metric_key
        );
      };
    },
  },
};
