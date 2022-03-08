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
        :point="displayMetric(metric.KEY)"
        :trend="calculateTrend(metric.KEY)"
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
import { GROUP_BY_FILTER } from './constants';
import { formatTime } from '@chatwoot/utils';

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
      currDateFrom: 0,
      currDateTo: 0,
      prevDateFrom: 0,
      prevDateTo: 0,
      currentSelection: 0,
      groupBy: GROUP_BY_FILTER[1],
      filterItemsList: this.$t('REPORT.GROUP_BY_DAY_OPTIONS'),
      selectedGroupByFilter: {},
    };
  },
  computed: {
    ...mapGetters({
      currentAccountSummary: 'getCurrentAccountSummary',
      previousAccountSummary: 'getPreviousAccountSummary',
      accountReport: 'getAccountReports',
    }),
    collection() {
      if (this.accountReport.isFetching) {
        return {};
      }
      if (!this.accountReport.data.length) return {};
      const labels = this.accountReport.data.map(element => {
        if (this.groupBy.period === GROUP_BY_FILTER[2].period) {
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
        if (this.groupBy.period === GROUP_BY_FILTER[3].period) {
          return format(fromUnixTime(element.timestamp), 'MMM-yyyy');
        }
        if (this.groupBy.period === GROUP_BY_FILTER[4].period) {
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
    calculateTrend() {
      return metric_key => {
        return Math.round(
          ((this.currentAccountSummary[metric_key] -
            this.previousAccountSummary[metric_key]) /
            this.previousAccountSummary[metric_key]) *
            100
        );
      };
    },
    displayMetric() {
      return metric_key => {
        if (metric_key === 'avg_first_response_time') {
          return formatTime(this.currentAccountSummary[metric_key]);
        }
        if (metric_key === 'avg_resolution_time') {
          return formatTime(this.currentAccountSummary[metric_key]);
        }
        return this.currentAccountSummary[metric_key];
      };
    },
  },
  methods: {
    fetchAllData() {
      const {
        currDateFrom,
        currDateTo,
        prevDateFrom,
        prevDateTo,
        groupBy,
      } = this;
      this.$store.dispatch('fetchAccountSummary', {
        currDateFrom,
        currDateTo,
        prevDateFrom,
        prevDateTo,
        groupBy: groupBy.period,
      });
      this.fetchChartData();
    },
    fetchChartData() {
      const { currDateFrom, currDateTo, groupBy } = this;
      this.$store.dispatch('fetchAccountReport', {
        metric: this.metrics[this.currentSelection].KEY,
        from: currDateFrom,
        to: currDateTo,
        groupBy: groupBy.period,
      });
    },
    downloadAgentReports() {
      const { currDateFrom, currDateTo } = this;
      const fileName = `agent-report-${format(
        fromUnixTime(currDateTo),
        'dd-MM-yyyy'
      )}.csv`;
      this.$store.dispatch('downloadAgentReports', {
        from: currDateFrom,
        to: currDateTo,
        fileName,
      });
    },
    changeSelection(index) {
      this.currentSelection = index;
      this.fetchChartData();
    },
    onDateRangeChange({ currentDateRange, previousDateRange, groupBy }) {
      this.currDateFrom = currentDateRange.from;
      this.currDateTo = currentDateRange.to;
      this.prevDateFrom = previousDateRange.from;
      this.prevDateTo = previousDateRange.to;
      this.filterItemsList = this.fetchFilterItems(groupBy);
      const filterItems = this.filterItemsList.filter(
        item => item.id === this.groupBy.id
      );
      if (filterItems.length > 0) {
        this.selectedGroupByFilter = filterItems[0];
      } else {
        this.selectedGroupByFilter = this.filterItemsList[0];
        this.groupBy = GROUP_BY_FILTER[this.selectedGroupByFilter.id];
      }
      this.fetchAllData();
    },
    onFilterChange(payload) {
      this.groupBy = GROUP_BY_FILTER[payload.id];
      this.fetchAllData();
    },
    fetchFilterItems(group_by) {
      switch (group_by) {
        case GROUP_BY_FILTER[2].period:
          return this.$t('REPORT.GROUP_BY_WEEK_OPTIONS');
        case GROUP_BY_FILTER[3].period:
          return this.$t('REPORT.GROUP_BY_MONTH_OPTIONS');
        case GROUP_BY_FILTER[4].period:
          return this.$t('REPORT.GROUP_BY_YEAR_OPTIONS');
        default:
          return this.$t('REPORT.GROUP_BY_DAY_OPTIONS');
      }
    },
  },
};
</script>
