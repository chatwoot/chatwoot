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
      group-by-filter
      :selected-group-by-filter="selectedGroupByFilter"
      :filter-items-list="filterItemsList"
      @date-range-change="onDateRangeChange"
      @filter-change="onFilterChange"
      @business-hours-toggle="onBusinessHoursToggle"
    />
    <div class="card" style="margin-bottom: 50px;">
      <div class="card-header">
        <h5>Conversations Heatmap</h5>
      </div>
      <div class="card-body row" style="margin-top: 1rem">
        <report-heatmap :heat-data="heatmapData" />
      </div>
    </div>
    <div class="row">
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
          v-if="accountReport.data.length"
          :collection="collection"
          :chart-options="chartOptions"
        />
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
import ReportHeatmap from './components/Heatmap';
import { GROUP_BY_FILTER, METRIC_CHART } from './constants';
import reportMixin from '../../../../mixins/reportMixin';
import { formatTime } from '@chatwoot/utils';
import { REPORTS_EVENTS } from '../../../../helper/AnalyticsHelper/events';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
};

const HEATMAP_DATA = [
  { value: 43, timestamp: 1676399400 },
  { value: 50, timestamp: 1676403000 },
  { value: 68, timestamp: 1676406600 },
  { value: 70, timestamp: 1676410200 },
  { value: 94, timestamp: 1676413800 },
  { value: 151, timestamp: 1676417400 },
  { value: 124, timestamp: 1676421000 },
  { value: 165, timestamp: 1676424600 },
  { value: 216, timestamp: 1676428200 },
  { value: 204, timestamp: 1676431800 },
  { value: 274, timestamp: 1676435400 },
  { value: 299, timestamp: 1676439000 },
  { value: 268, timestamp: 1676442600 },
  { value: 308, timestamp: 1676446200 },
  { value: 207, timestamp: 1676449800 },
  { value: 173, timestamp: 1676453400 },
  { value: 123, timestamp: 1676457000 },
  { value: 67, timestamp: 1676460600 },
  { value: 70, timestamp: 1676464200 },
  { value: 41, timestamp: 1676467800 },
  { value: 34, timestamp: 1676471400 },
  { value: 17, timestamp: 1676475000 },
  { value: 4, timestamp: 1676478600 },
  { value: 4, timestamp: 1676482200 },
  { value: 52, timestamp: 1676485800 },
  { value: 62, timestamp: 1676489400 },
  { value: 75, timestamp: 1676493000 },
  { value: 74, timestamp: 1676496600 },
  { value: 97, timestamp: 1676500200 },
  { value: 160, timestamp: 1676503800 },
  { value: 163, timestamp: 1676507400 },
  { value: 170, timestamp: 1676511000 },
  { value: 213, timestamp: 1676514600 },
  { value: 201, timestamp: 1676518200 },
  { value: 279, timestamp: 1676521800 },
  { value: 120, timestamp: 1676525400 },
  { value: 271, timestamp: 1676529000 },
  { value: 307, timestamp: 1676532600 },
  { value: 218, timestamp: 1676536200 },
  { value: 169, timestamp: 1676539800 },
  { value: 121, timestamp: 1676543400 },
  { value: 69, timestamp: 1676547000 },
  { value: 72, timestamp: 1676550600 },
  { value: 42, timestamp: 1676554200 },
  { value: 37, timestamp: 1676557800 },
  { value: 19, timestamp: 1676561400 },
  { value: 6, timestamp: 1676565000 },
  { value: 7, timestamp: 1676568600 },
  { value: 18, timestamp: 1676572200 },
  { value: 109, timestamp: 1676575800 },
  { value: 106, timestamp: 1676579400 },
  { value: 109, timestamp: 1676583000 },
  { value: 174, timestamp: 1676586600 },
  { value: 138, timestamp: 1676590200 },
  { value: 194, timestamp: 1676593800 },
  { value: 242, timestamp: 1676597400 },
  { value: 240, timestamp: 1676601000 },
  { value: 315, timestamp: 1676604600 },
  { value: 325, timestamp: 1676608200 },
  { value: 276, timestamp: 1676611800 },
  { value: 390, timestamp: 1676615400 },
  { value: 318, timestamp: 1676619000 },
  { value: 224, timestamp: 1676622600 },
  { value: 181, timestamp: 1676626200 },
  { value: 318, timestamp: 1676629800 },
  { value: 137, timestamp: 1676633400 },
  { value: 81, timestamp: 1676637000 },
  { value: 89, timestamp: 1676640600 },
  { value: 55, timestamp: 1676644200 },
  { value: 32, timestamp: 1676647800 },
  { value: 61, timestamp: 1676651400 },
  { value: 31, timestamp: 1676655000 },
  // -------
  { value: 84, timestamp: 1676658600 },
  { value: 110, timestamp: 1676662200 },
  { value: 97, timestamp: 1676665800 },
  { value: 100, timestamp: 1676669400 },
  { value: 146, timestamp: 1676673000 },
  { value: 199, timestamp: 1676676600 },
  { value: 140, timestamp: 1676680200 },
  { value: 199, timestamp: 1676683800 },
  { value: 218, timestamp: 1676687400 },
  { value: 277, timestamp: 1676691000 },
  { value: 205, timestamp: 1676694600 },
  { value: 275, timestamp: 1676698200 },
  { value: 302, timestamp: 1676701800 },
  { value: 291, timestamp: 1676705400 },
  { value: 148, timestamp: 1676709000 },
  { value: 265, timestamp: 1676712600 },
  { value: 147, timestamp: 1676716200 },
  { value: 119, timestamp: 1676719800 },
  { value: 122, timestamp: 1676723400 },
  { value: 66, timestamp: 1676727000 },
  { value: 15, timestamp: 1676730600 },
  { value: 6, timestamp: 1676734200 },
  { value: 58, timestamp: 1676737800 },
  { value: 61, timestamp: 1676741400 },
  { value: 45, timestamp: 1676745000 },
  { value: 95, timestamp: 1676748600 },
  { value: 62, timestamp: 1676752200 },
  { value: 122, timestamp: 1676755800 },
  { value: 79, timestamp: 1676759400 },
  { value: 151, timestamp: 1676763000 },
  { value: 137, timestamp: 1676766600 },
  { value: 171, timestamp: 1676770200 },
  { value: 328, timestamp: 1676773800 },
  { value: 211, timestamp: 1676777400 },
  { value: 279, timestamp: 1676781000 },
  { value: 260, timestamp: 1676784600 },
  { value: 221, timestamp: 1676788200 },
  { value: 368, timestamp: 1676791800 },
  { value: 203, timestamp: 1676795400 },
  { value: 225, timestamp: 1676799000 },
  { value: 124, timestamp: 1676802600 },
  { value: 58, timestamp: 1676806200 },
  { value: 102, timestamp: 1676809800 },
  { value: 45, timestamp: 1676813400 },
  { value: 46, timestamp: 1676817000 },
  { value: 60, timestamp: 1676820600 },
  { value: 0, timestamp: 1676824200 },
  { value: 10, timestamp: 1676827800 },
  { value: 113, timestamp: 1676831400 },
  { value: 115, timestamp: 1676835000 },
  { value: 138, timestamp: 1676838600 },
  { value: 134, timestamp: 1676842200 },
  { value: 236, timestamp: 1676845800 },
  { value: 170, timestamp: 1676849400 },
  { value: 217, timestamp: 1676853000 },
  { value: 291, timestamp: 1676856600 },
  { value: 367, timestamp: 1676860200 },
  { value: 348, timestamp: 1676863800 },
  { value: 191, timestamp: 1676867400 },
  { value: 277, timestamp: 1676871000 },
  { value: 345, timestamp: 1676874600 },
  { value: 243, timestamp: 1676878200 },
  { value: 383, timestamp: 1676881800 },
  { value: 281, timestamp: 1676885400 },
  { value: 191, timestamp: 1676889000 },
  { value: 143, timestamp: 1676892600 },
  { value: 97, timestamp: 1676896200 },
  { value: 147, timestamp: 1676899800 },
  { value: 89, timestamp: 1676903400 },
  { value: 121, timestamp: 1676907000 },
  { value: 81, timestamp: 1676910600 },
  { value: 16, timestamp: 1676914200 },
  { value: 69, timestamp: 1676917800 },
  { value: 35, timestamp: 1676921400 },
  { value: 112, timestamp: 1676925000 },
  { value: 12, timestamp: 1676928600 },
  { value: 228, timestamp: 1676932200 },
  { value: 106, timestamp: 1676935800 },
  { value: 96, timestamp: 1676939400 },
  { value: 103, timestamp: 1676943000 },
  { value: 200, timestamp: 1676946600 },
  { value: 144, timestamp: 1676950200 },
  { value: 353, timestamp: 1676953800 },
  { value: 270, timestamp: 1676957400 },
  { value: 341, timestamp: 1676961000 },
  { value: 347, timestamp: 1676964600 },
  { value: 148, timestamp: 1676968200 },
  { value: 241, timestamp: 1676971800 },
  { value: 83, timestamp: 1676975400 },
  { value: 69, timestamp: 1676979000 },
  { value: 50, timestamp: 1676982600 },
  { value: 31, timestamp: 1676986200 },
  { value: 21, timestamp: 1676989800 },
  { value: 30, timestamp: 1676993400 },
  { value: 20, timestamp: 1676997000 },
  { value: 46, timestamp: 1677000600 },
  { value: 47, timestamp: 1677004200 },
  { value: 45, timestamp: 1677007800 },
  { value: 74, timestamp: 1677011400 },
  { value: 72, timestamp: 1677015000 },
  { value: 94, timestamp: 1677018600 },
  { value: 148, timestamp: 1677022200 },
  { value: 130, timestamp: 1677025800 },
  { value: 177, timestamp: 1677029400 },
  { value: 212, timestamp: 1677033000 },
  { value: 199, timestamp: 1677036600 },
  { value: 269, timestamp: 1677040200 },
  { value: 273, timestamp: 1677043800 },
  { value: 301, timestamp: 1677047400 },
  { value: 180, timestamp: 1677051000 },
  { value: 314, timestamp: 1677054600 },
  { value: 212, timestamp: 1677058200 },
  { value: 124, timestamp: 1677061800 },
  { value: 62, timestamp: 1677065400 },
  { value: 80, timestamp: 1677069000 },
  { value: 46, timestamp: 1677072600 },
  { value: 43, timestamp: 1677076200 },
  { value: 19, timestamp: 1677079800 },
  { value: 2, timestamp: 1677083400 },
  { value: 9, timestamp: 1677087000 },
];

export default {
  name: 'ConversationReports',
  components: {
    ReportFilterSelector,
    ReportHeatmap,
  },
  mixins: [reportMixin],
  data() {
    return {
      from: 0,
      to: 0,
      currentSelection: 0,
      groupBy: GROUP_BY_FILTER[1],
      filterItemsList: this.$t('REPORT.GROUP_BY_DAY_OPTIONS'),
      selectedGroupByFilter: {},
      businessHours: false,
      heatmapData: HEATMAP_DATA,
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
      let tooltips = {};
      if (this.isAverageMetricType(this.metrics[this.currentSelection].KEY)) {
        tooltips.callbacks = {
          label: tooltipItem => {
            return this.$t(this.metrics[this.currentSelection].TOOLTIP_TEXT, {
              metricValue: formatTime(tooltipItem.yLabel),
              conversationCount: this.accountReport.data[tooltipItem.index]
                .count,
            });
          },
        };
      }

      return {
        scales: METRIC_CHART[this.metrics[this.currentSelection].KEY].scales,
        tooltips: tooltips,
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
      const infoText = {
        FIRST_RESPONSE_TIME: this.$t(
          `REPORT.METRICS.FIRST_RESPONSE_TIME.INFO_TEXT`
        ),
        RESOLUTION_TIME: this.$t(`REPORT.METRICS.RESOLUTION_TIME.INFO_TEXT`),
      };
      return reportKeys.map(key => ({
        NAME: this.$t(`REPORT.METRICS.${key}.NAME`),
        KEY: REPORTS_KEYS[key],
        DESC: this.$t(`REPORT.METRICS.${key}.DESC`),
        INFO_TEXT: infoText[key],
        TOOLTIP_TEXT: `REPORT.METRICS.${key}.TOOLTIP_TEXT`,
      }));
    },
  },
  methods: {
    fetchAllData() {
      const { from, to, groupBy, businessHours } = this;
      this.$store.dispatch('fetchAccountSummary', {
        from,
        to,
        groupBy: groupBy.period,
        businessHours,
      });
      this.fetchChartData();
    },
    fetchChartData() {
      const { from, to, groupBy, businessHours } = this;
      this.$store.dispatch('fetchAccountReport', {
        metric: this.metrics[this.currentSelection].KEY,
        from,
        to,
        groupBy: groupBy.period,
        businessHours,
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
      // do not track filter change on inital load
      if (this.from !== 0 && this.to !== 0) {
        this.$track(REPORTS_EVENTS.FILTER_REPORT, {
          filterType: 'date',
          reportType: 'conversations',
        });
      }
      this.from = from;
      this.to = to;
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

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterType: 'groupBy',
        filterValue: this.groupBy?.period,
        reportType: 'conversations',
      });
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
    onBusinessHoursToggle(value) {
      this.businessHours = value;
      this.fetchAllData();

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterType: 'businessHours',
        filterValue: value,
        reportType: 'conversations',
      });
    },
  },
};
</script>
