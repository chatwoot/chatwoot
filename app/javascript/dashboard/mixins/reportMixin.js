import { mapGetters } from 'vuex';
import { formatTime } from '@chatwoot/utils';

export default {
  computed: {
    ...mapGetters({
      accountSummary: 'getAccountSummary',
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
        if (
          ['avg_first_response_time', 'avg_resolution_time'].includes(
            metric_key
          )
        ) {
          return formatTime(this.accountSummary[metric_key]);
        }
        return this.accountSummary[metric_key];
      };
    },
  },
};
