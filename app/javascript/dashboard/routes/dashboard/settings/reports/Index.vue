<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="arrow-download"
      @click="downloadAgentReports"
    >
      {{ $t('REPORT.DOWNLOAD_AGENT_REPORTS') }}
    </woot-button>

    <report-filter-selector
      :selected-group-by-filter="selectedGroupByFilter"
      :filter-items-list="filterItemsList"
      @date-range-change="onDateRangeChange"
      @filter-change="onFilterChange"
    />
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
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import ReportFilterSelector from './components/FilterSelector';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
};

export default {
  components: {
    ReportFilterSelector,
  },
  data() {
    return {
      from: 0,
      to: 0,
      currentSelection: 0,
      groupBy: 'day',
      groupByOptions: {
        day: [{ id: 1, groupBy: 'Day' }],
        week: [
          { id: 1, groupBy: 'Day' },
          { id: 2, groupBy: 'Week' },
        ],
        month: [
          { id: 1, groupBy: 'Day' },
          { id: 2, groupBy: 'Week' },
          { id: 3, groupBy: 'Month' },
        ],
        year: [
          { id: 1, groupBy: 'Day' },
          { id: 2, groupBy: 'Week' },
          { id: 3, groupBy: 'Month' },
          { id: 4, groupBy: 'Year' },
        ],
      },
      filterItemsList: [],
      selectedGroupByFilter: {},
    };
  },
  computed: {
    ...mapGetters({
      accountSummary: 'getAccountSummary',
      accountReport: 'getAccountReports',
    }),
    collection() {
      if (this.accountReport.isFetching) {
        return {};
      }
      if (!this.accountReport.data.length) return {};
      const labels = this.accountReport.data.map(element => {
        if (this.groupBy === 'month') {
          return format(fromUnixTime(element.timestamp), 'MMM-yyyy');
        }
        if (this.groupBy === 'week') {
          let week_date = new Date(fromUnixTime(element.timestamp));
          const first_day = week_date.getDate() - week_date.getDay();
          const last_day = first_day + 6;

          const week_first_date = new Date(week_date.setDate(first_day));
          const week_last_date = new Date(week_date.setDate(last_day));

          return `${format(week_first_date, 'dd/MM/yy')} - ${format(
            week_last_date,
            'dd/MM/yy'
          )}`;
        }
        if (this.groupBy === 'year') {
          return format(fromUnixTime(element.timestamp), 'yyyy');
        }
        return format(fromUnixTime(element.timestamp), 'dd-MMM-yyyy');
      });
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
    this.filterItemsList = this.groupByOptions[this.groupBy];
    this.selectedGroupByFilter = this.filterItemsList[0];
  },
  methods: {
    fetchAllData() {
      const { from, to, groupBy } = this;
      this.$store.dispatch('fetchAccountSummary', { from, to, groupBy });
      this.fetchChartData();
    },
    fetchChartData() {
      const { from, to, groupBy } = this;
      this.$store.dispatch('fetchAccountReport', {
        metric: this.metrics[this.currentSelection].KEY,
        from,
        to,
        groupBy,
      });
    },
    downloadAgentReports() {
      const { from, to } = this;
      const fileName = `agent-report-${format(
        fromUnixTime(to),
        'dd-MM-yyyy'
      )}.csv`;
      this.$store.dispatch('downloadAgentReports', { from, to, fileName });
    },
    changeSelection(index) {
      this.currentSelection = index;
      this.fetchChartData();
    },
    onDateRangeChange({ from, to, groupBy }) {
      this.from = from;
      this.to = to;
      this.filterItemsList = this.groupByOptions[groupBy];
      const filterItems = this.filterItemsList.filter(
        item => item.groupBy.toLowerCase() === this.groupBy
      );
      if (filterItems.length > 0) {
        this.selectedGroupByFilter = filterItems[0];
      } else {
        this.selectedGroupByFilter = this.filterItemsList[0];
        this.groupBy = this.selectedGroupByFilter.groupBy.toLowerCase();
      }
      this.fetchAllData();
    },
    onFilterChange(payload) {
      this.groupBy = payload.groupBy.toLowerCase();
      this.fetchAllData();
    },
  },
};
</script>
