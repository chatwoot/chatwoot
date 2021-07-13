<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="ion-android-download"
      @click="downloadAgentReports"
    >
      {{ $t('REPORT.DOWNLOAD_AGENT_REPORTS') }}
    </woot-button>
    <div class="range-selector">
      <div class="small-3 pull-right">
        <multiselect
          v-model="currentDateRangeSelection"
          track-by="name"
          label="name"
          :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
          selected-label
          :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
          deselect-label=""
          :options="dateRange"
          :searchable="false"
          :allow-empty="false"
          @select="changeDateSelection"
        />
      </div>
      <woot-date-range-picker
        v-if="isDateRangeSelected"
        :value="customDateRange"
        :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
        :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
        @change="onChange"
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
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
};

const CUSTOM_DATE_RANGE_ID = 5;

export default {
  components: {
    WootDateRangePicker,
  },
  data() {
    return {
      currentSelection: 0,
      currentDateRangeSelection: this.$t('REPORT.DATE_RANGE')[0],
      dateRange: this.$t('REPORT.DATE_RANGE'),
      customDateRange: [new Date(), new Date()],
    };
  },
  computed: {
    ...mapGetters({
      accountSummary: 'getAccountSummary',
      accountReport: 'getAccountReports',
    }),
    to() {
      if (this.isDateRangeSelected) {
        return this.fromCustomDate(this.customDateRange[1]);
      }
      return this.fromCustomDate(new Date());
    },
    from() {
      if (this.isDateRangeSelected) {
        return this.fromCustomDate(this.customDateRange[0]);
      }
      const dateRange = {
        0: 6,
        1: 29,
        2: 89,
        3: 179,
        4: 364,
      };
      const diff = dateRange[this.currentDateRangeSelection.id];
      const fromDate = subDays(new Date(), diff);
      return this.fromCustomDate(fromDate);
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
    isDateRangeSelected() {
      return this.currentDateRangeSelection.id === CUSTOM_DATE_RANGE_ID;
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
    fromCustomDate(date) {
      return getUnixTime(startOfDay(date));
    },
    onChange(value) {
      this.customDateRange = value;
      this.fetchAllData();
    },
  },
};
</script>
<style lang="scss" scoped>
.range-selector {
  display: flex;
}
</style>
