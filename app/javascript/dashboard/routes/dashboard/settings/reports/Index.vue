<template>
  <div class="column content-box">
    <button
      class="button nice icon success button--fixed-right-top"
      @click="downloadAgentReports"
    >
      <i class="icon ion-android-download"></i>
      {{ $t('REPORT.DOWNLOAD_AGENT_REPORTS') }}
    </button>
    <div class="small-3 pull-right">
      <multiselect
        v-model="currentDateRangeSelection"
        track-by="name"
        label="name"
        :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
        :options="dateRange"
        :searchable="false"
        :allow-empty="true"
        @select="changeDateSelection"
      />
    </div>
    <div class="row">
      <woot-report-stats-card
        v-for="(metric, index) in metrics"
        :key="metric.NAME"
        :desc="metric.DESC"
        :heading="metric.NAME"
        :index="index"
        :on-click="changeSelection"
        :point="accountSummary[metric.KEY]"
        :selected="index === currentSelection"
      />
    </div>
    <div class="report-bar">
      <woot-loading-state
        v-if="accountReport.isFetching"
        :message="$t('REPORT.LOADING_CHART')"
      />
      <div v-else class="chart-container">
        <woot-bar v-if="accountReport.data.length" :collection="collection" />
        <span v-else class="empty-state">
          {{ $t('REPORT.NO_ENOUGH_DATA') }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import getUnixTime from 'date-fns/getUnixTime';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
};

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
      return getUnixTime(startOfDay(new Date()));
    },
    from() {
      const dateRange = {
        0: 6,
        1: 29,
        2: 89,
        3: 179,
        4: 364,
      };
      const diff = dateRange[this.currentDateRangeSelection.id];
      const fromDate = subDays(new Date(), diff);
      return getUnixTime(startOfDay(fromDate));
    },
    collection() {
      if (this.accountReport.isFetching) {
        return {};
      }
      if (!this.accountReport.data.length) return {};
      const labels = this.accountReport.data.map(element =>
        format(fromUnixTime(element.timestamp), 'dd/MMM')
      );
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
      const reportKeys = [
        'CONVERSATIONS',
        'INCOMING_MESSAGES',
        'OUTGOING_MESSAGES',
        'FIRST_RESPONSE_TIME',
        'RESOLUTION_TIME',
        'RESOLUTION_COUNT',
      ];
      return reportKeys.map(key => ({
        NAME: this.$t(`REPORT.METRICS.${key}.NAME`),
        KEY: REPORTS_KEYS[key],
        DESC: this.$t(`REPORT.METRICS.${key}.DESC`),
      }));
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
    downloadAgentReports() {
      const { from, to } = this;
      this.$store.dispatch('downloadAgentReports', {
        from,
        to,
      });
    },
  },
};
</script>
