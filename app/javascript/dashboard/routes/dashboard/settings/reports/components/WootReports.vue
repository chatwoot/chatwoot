<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="arrow-download"
      @click="downloadReports"
    >
      {{ downloadButtonLabel }}
    </woot-button>
    <report-filters
      v-if="filterItemsList"
      :type="type"
      :filter-items-list="filterItemsList"
      :group-by-filter-items-list="groupByfilterItemsList"
      :selected-group-by-filter="selectedGroupByFilter"
      @date-range-change="onDateRangeChange"
      @filter-change="onFilterChange"
      @group-by-filter-change="onGroupByFilterChange"
    />
    <div>
      <div v-if="filterItemsList.length" class="row">
        <woot-report-stats-card
          v-for="(metric, index) in metrics"
          :key="metric.NAME"
          :desc="metric.DESC"
          :heading="metric.NAME"
          :info-text="displayInfoText(metric.KEY)"
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
          <woot-bar
            v-if="accountReport.data.length && filterItemsList.length"
            :collection="collection"
            :chart-options="chartOptions"
          />
          <span v-else class="empty-state">
            {{ $t('REPORT.NO_ENOUGH_DATA') }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ReportFilters from './ReportFilters';
import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import { GROUP_BY_FILTER, METRIC_CHART } from '../constants';
import reportMixin from '../../../../../mixins/reportMixin';

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
    ReportFilters,
  },
  mixins: [reportMixin],
  props: {
    type: {
      type: String,
      default: 'account',
    },
    getterKey: {
      type: String,
      default: '',
    },
    actionKey: {
      type: String,
      default: '',
    },
    downloadButtonLabel: {
      type: String,
      default: 'Download Reports',
    },
  },
  data() {
    return {
      from: 0,
      to: 0,
      currentSelection: 0,
      selectedFilter: null,
      groupBy: GROUP_BY_FILTER[1],
      groupByfilterItemsList: this.$t('REPORT.GROUP_BY_DAY_OPTIONS'),
      selectedGroupByFilter: null,
    };
  },
  computed: {
    filterItemsList() {
      return this.$store.getters[this.getterKey] || [];
    },
    accountSummary() {
      return this.$store.getters.getAccountSummary || [];
    },
    accountReport() {
      return this.$store.getters.getAccountReports || [];
    },
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

      const datasets = METRIC_CHART[
        this.metrics[this.currentSelection].KEY
      ].datasets.map(dataset => {
        switch (dataset.type) {
          case 'bar':
            return {
              ...dataset,
              yAxisID: 'y-left',
              label: this.metrics[this.currentSelection].NAME,
              data: this.accountReport.data.map(element => element.value),
            };
          case 'line':
            return {
              ...dataset,
              yAxisID: 'y-right',
              label: this.metrics[0].NAME,
              data: this.accountReport.data.map(element => element.count),
            };
          default:
            return dataset;
        }
      });

      return {
        labels,
        datasets,
      };
    },
    chartOptions() {
      return {
        scales: METRIC_CHART[this.metrics[this.currentSelection].KEY].scales,
      };
    },
    metrics() {
      let reportKeys = ['CONVERSATIONS'];
      // If report type is agent, we don't need to show
      // incoming messages count, as there will not be any message
      // sent by an agent which is incoming.
      if (this.type !== 'agent') {
        reportKeys.push('INCOMING_MESSAGES');
      }
      reportKeys = [
        ...reportKeys,
        'OUTGOING_MESSAGES',
        'FIRST_RESPONSE_TIME',
        'RESOLUTION_TIME',
        'RESOLUTION_COUNT',
      ];
      return reportKeys.map(key => ({
        NAME: this.$t(`REPORT.METRICS.${key}.NAME`),
        KEY: REPORTS_KEYS[key],
        DESC: this.$t(`REPORT.METRICS.${key}.DESC`),
        INFO_TEXT: this.$t(`REPORT.METRICS.${key}.INFO_TEXT`),
      }));
    },
  },
  mounted() {
    this.$store.dispatch(this.actionKey);
  },
  methods: {
    fetchAllData() {
      if (this.selectedFilter) {
        const { from, to, groupBy } = this;
        this.$store.dispatch('fetchAccountSummary', {
          from,
          to,
          type: this.type,
          id: this.selectedFilter.id,
          groupBy: groupBy.period,
        });
        this.fetchChartData();
      }
    },
    fetchChartData() {
      const { from, to, groupBy } = this;
      this.$store.dispatch('fetchAccountReport', {
        metric: this.metrics[this.currentSelection].KEY,
        from,
        to,
        type: this.type,
        id: this.selectedFilter.id,
        groupBy: groupBy.period,
      });
    },
    downloadReports() {
      const { from, to } = this;
      const fileName = `${this.type}-report-${format(
        fromUnixTime(to),
        'dd-MM-yyyy'
      )}.csv`;
      switch (this.type) {
        case 'agent':
          this.$store.dispatch('downloadAgentReports', { from, to, fileName });
          break;
        case 'label':
          this.$store.dispatch('downloadLabelReports', { from, to, fileName });
          break;
        case 'inbox':
          this.$store.dispatch('downloadInboxReports', { from, to, fileName });
          break;
        case 'team':
          this.$store.dispatch('downloadTeamReports', { from, to, fileName });
          break;
        default:
          break;
      }
    },
    changeSelection(index) {
      this.currentSelection = index;
      this.fetchChartData();
    },
    onDateRangeChange({ from, to, groupBy }) {
      this.from = from;
      this.to = to;
      this.groupByfilterItemsList = this.fetchFilterItems(groupBy);
      const filterItems = this.groupByfilterItemsList.filter(
        item => item.id === this.groupBy.id
      );
      if (filterItems.length > 0) {
        this.selectedGroupByFilter = filterItems[0];
      } else {
        this.selectedGroupByFilter = this.groupByfilterItemsList[0];
        this.groupBy = GROUP_BY_FILTER[this.selectedGroupByFilter.id];
      }
      this.fetchAllData();
    },
    onFilterChange(payload) {
      if (payload) {
        this.selectedFilter = payload;
        this.fetchAllData();
      }
    },
    onGroupByFilterChange(payload) {
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
