import { mapGetters } from 'vuex';
import { formatTime } from '@chatwoot/utils';

export default {
  props: {
    accountSummaryKey: {
      type: String,
      default: 'getAccountSummary',
    },
    templateSummaryKey: {
      type: String,
      default: 'getTemplateSummary',
    },
  },
  computed: {
    ...mapGetters({
      accountReport: 'getAccountReports',
      templateReport: 'getTemplateReports',
      templateSummary: 'getTemplateSummary',
    }),
    templateSummary() {
      return this.$store.getters[this.templateSummaryKey];
    },
    accountSummary() {
      return this.$store.getters[this.accountSummaryKey];
    },
    isUsingAccountSummary() {
      return this.$store.getters['getIsAccountSummaryAvailable'];
    },
  },

  methods: {
    calculateTrend(key) {
      const summary = this.isUsingAccountSummary
        ? this.accountSummary
        : this.templateSummary;

      if (!summary.previous[key]) return 0;
      const diff = summary[key] - summary.previous[key];
      return Math.round((diff / summary.previous[key]) * 100);
    },
    displayMetric(key) {
      const summary = this.isUsingAccountSummary
        ? this.accountSummary
        : this.templateSummary;

      if (this.isAverageMetricType(key)) {
        return formatTime(summary[key]);
      }
      return Number(summary[key] || '').toLocaleString();
    },
    displayInfoText(key) {
      const reportData = this.isUsingAccountSummary
        ? this.accountReport.data
        : this.templateReport.data;

      if (this.metrics[this.currentSelection].KEY !== key) {
        return '';
      }
      if (this.isAverageMetricType(key)) {
        const total = reportData
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
