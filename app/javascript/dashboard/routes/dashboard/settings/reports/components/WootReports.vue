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
      @date-range-change="onDateRangeChange"
      @filter-change="onFilterChange"
    />
    <div>
      <div v-if="filterItemsList.length" class="row">
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
          <woot-bar
            v-if="accountReport.data.length && filterItemsList.length"
            :collection="collection"
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
      }));
    },
  },
  mounted() {
    this.$store.dispatch(this.actionKey);
  },
  methods: {
    fetchAllData() {
      if (this.selectedFilter) {
        const { from, to } = this;
        this.$store.dispatch('fetchAccountSummary', {
          from,
          to,
          type: this.type,
          id: this.selectedFilter.id,
        });
        this.fetchChartData();
      }
    },
    fetchChartData() {
      const { from, to } = this;
      this.$store.dispatch('fetchAccountReport', {
        metric: this.metrics[this.currentSelection].KEY,
        from,
        to,
        type: this.type,
        id: this.selectedFilter.id,
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
    onDateRangeChange({ from, to }) {
      this.from = from;
      this.to = to;
      this.fetchAllData();
    },
    onFilterChange(payload) {
      if (payload) {
        this.selectedFilter = payload;
        this.fetchAllData();
      }
    },
  },
};
</script>
