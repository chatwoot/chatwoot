import { mapGetters } from 'vuex';
import { formatTime } from '@chatwoot/utils';

export default {
  props: {
    accountSummaryKey: {
      type: String,
      default: 'getAccountSummary',
    },
  },
  computed: {
    ...mapGetters({
      accountReport: 'getAccountReports',
    }),
    accountSummary() {
      return this.$store.getters[this.accountSummaryKey];
    },
  },
  methods: {
    calculateTrend(key) {
      if (!this.accountSummary.previous[key]) return 0;
      const diff = this.accountSummary[key] - this.accountSummary.previous[key];
      return Math.round((diff / this.accountSummary.previous[key]) * 100);
    },
    displayMetric(key) {
      if (this.isAverageMetricType(key)) {
        return formatTime(this.accountSummary[key]);
      }
      return Number(this.accountSummary[key] || '').toLocaleString();
    },
    displayInfoText(key) {
      if (this.metrics[this.currentSelection].KEY !== key) {
        return '';
      }
      if (this.isAverageMetricType(key)) {
        const total = this.accountReport.data
          .map(item => item.count)
          .reduce((prev, curr) => prev + curr, 0);
        return `${this.metrics[this.currentSelection].INFO_TEXT} ${total}`;
      }
      return '';
    },
    isAverageMetricType(key) {
      return [
        'avg_first_response_time',
        'avg_resolution_time',
        'reply_time',
      ].includes(key);
    },
  },
};
