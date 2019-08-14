<template>
  <div class="column content-box">
    <div class="small-3 pull-right">
      <multiselect
        v-model="currentDateRangeSelection"
        track-by="name"
        label="name"
        @select="changeDateSelection"
        placeholder="Select one"
        :options="dateRange"
        :searchable="false"
        :allow-empty="true"
      />
    </div>
    <div class="row">
      <woot-report-stats-card
        v-for="(metric, index) in metrics"
        :heading="metric.NAME"
        :point="accountSummary[metric.KEY]"
        :desc="metric.DESC"
        :index="index"
        :selected="index === currentSelection"
        :on-click="changeSelection"
      />
    </div>
    <div class="report-bar">
      <woot-loading-state :message="$t('REPORT.LOADING_CHART')" v-if="accountReport.isFetching"></woot-loading-state>
      <div v-else class="chart-container">
        <woot-bar :collection="collection" v-if="accountReport.data.length"/>
        <span class="empty-state" v-else v-html="$t('REPORT.NO_ENOUGH_DATA')" />
      </div>
    </div>
  </div>
</template>


<script>

import { mapGetters } from 'vuex';
import moment from 'moment';

export default {
  data() {
    return {
      currentSelection: 0,
      currentDateRangeSelection: this.$t('REPORT.DATE_RANGE')[0],
      dateRange: this.$t('REPORT.DATE_RANGE'),
    };
  },
  computed: {
    ...mapGetters({
      accountSummary: 'getAccountSummary',
      accountReport: 'getAccountReports',
    }),
    to() {
      const m = moment.utc();
      m.set({ hour: 23, minute: 59, second: 59, millisecond: 999 });
      return m.unix();
    },
    from() {
      const diff = this.currentDateRangeSelection.id ? 29 : 6;
      const m = moment.utc().subtract(diff, 'days');
      m.set({ hour: 0, minute: 0, second: 0, millisecond: 0 });
      return m.unix();
    },
    collection() {
      if (this.accountReport.isFetching) {
        return {};
      }
      if (!this.accountReport.data.length) return {};
      const labels = this.accountReport.data.map(element => moment.unix(element.timestamp).format('DD/MMM'));
      const data = this.accountReport.data.map(element => element.value);
      return {
        labels,
        datasets: [
          {
            label: this.metrics[this.currentSelection].NAME,
            backgroundColor: '#1f93ff',
            data,
          },
        ],
      };
    },
    metrics() {
      return this.$t('REPORT.METRICS');
    },
  },
  mounted() {
    this.fetchAllData();
  },
  methods: {
    fetchAllData() {
      const { from, to } = this;
      this.$store.dispatch('fetchAccountSummary', {
        from,
        to,
      });
      this.$store.dispatch('fetchAccountReport', {
        metric: this.metrics[this.currentSelection].KEY,
        from,
        to,
      });
    },
    changeDateSelection(selectedRange) {
      this.currentDateRangeSelection = selectedRange;
      this.fetchAllData();
    },
    changeSelection(index) {
      this.currentSelection = index;
      this.fetchChartData();
    },
    fetchChartData() {
      const { from, to } = this;
      this.$store.dispatch('fetchAccountReport', {
        metric: this.metrics[this.currentSelection].KEY,
        from,
        to,
      });
    },
  },
};
</script>
