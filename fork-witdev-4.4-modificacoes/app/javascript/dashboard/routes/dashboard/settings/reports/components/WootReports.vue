<script>
import V4Button from 'dashboard/components-next/button/Button.vue';
import { useAlert, useTrack } from 'dashboard/composables';
import ReportFilters from './ReportFilters.vue';
import ReportContainer from '../ReportContainer.vue';
import { GROUP_BY_FILTER } from '../constants';
import { generateFileName } from '../../../../../helper/downloadHelper';
import { REPORTS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';
import ReportHeader from './ReportHeader.vue';

const GROUP_BY_OPTIONS = {
  DAY: [{ id: 1, groupByKey: 'REPORT.GROUPING_OPTIONS.DAY' }],
  WEEK: [
    { id: 1, groupByKey: 'REPORT.GROUPING_OPTIONS.DAY' },
    { id: 2, groupByKey: 'REPORT.GROUPING_OPTIONS.WEEK' },
  ],
  MONTH: [
    { id: 1, groupByKey: 'REPORT.GROUPING_OPTIONS.DAY' },
    { id: 2, groupByKey: 'REPORT.GROUPING_OPTIONS.WEEK' },
    { id: 3, groupByKey: 'REPORT.GROUPING_OPTIONS.MONTH' },
  ],
  YEAR: [
    { id: 2, groupByKey: 'REPORT.GROUPING_OPTIONS.WEEK' },
    { id: 3, groupByKey: 'REPORT.GROUPING_OPTIONS.MONTH' },
    { id: 4, groupByKey: 'REPORT.GROUPING_OPTIONS.YEAR' },
  ],
};

export default {
  components: {
    ReportHeader,
    V4Button,
    ReportFilters,
    ReportContainer,
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
    reportTitle: {
      type: String,
      default: 'Download Reports',
    },
    hasBackButton: {
      type: Boolean,
      default: false,
    },
    selectedItem: {
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      from: 0,
      to: 0,
      selectedFilter: this.selectedItem,
      groupBy: GROUP_BY_FILTER[1],
      groupByfilterItemsList: GROUP_BY_OPTIONS.DAY.map(this.translateOptions),
      selectedGroupByFilter: null,
      businessHours: false,
    };
  },
  computed: {
    filterItemsList() {
      return this.$store.getters[this.getterKey] || [];
    },
    isAgentType() {
      return this.type === 'agent';
    },
    reportKeys() {
      return {
        CONVERSATIONS: 'conversations_count',
        ...(!this.isAgentType && {
          INCOMING_MESSAGES: 'incoming_messages_count',
        }),
        OUTGOING_MESSAGES: 'outgoing_messages_count',
        FIRST_RESPONSE_TIME: 'avg_first_response_time',
        RESOLUTION_TIME: 'avg_resolution_time',
        RESOLUTION_COUNT: 'resolutions_count',
        REPLY_TIME: 'reply_time',
      };
    },
  },
  mounted() {
    this.$store.dispatch(this.actionKey);
  },
  methods: {
    fetchAllData() {
      if (this.selectedFilter) {
        const { from, to, groupBy, businessHours } = this;
        this.$store.dispatch('fetchAccountSummary', {
          from,
          to,
          type: this.type,
          id: this.selectedFilter.id,
          groupBy: groupBy.period,
          businessHours,
        });
        this.fetchChartData();
      }
    },
    fetchChartData() {
      Object.keys(this.reportKeys).forEach(async key => {
        try {
          const { from, to, groupBy, businessHours } = this;
          this.$store.dispatch('fetchAccountReport', {
            metric: this.reportKeys[key],
            from,
            to,
            type: this.type,
            id: this.selectedFilter.id,
            groupBy: groupBy.period,
            businessHours,
          });
        } catch {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },
    downloadReports() {
      const { from, to, type, businessHours } = this;
      const dispatchMethods = {
        agent: 'downloadAgentReports',
        label: 'downloadLabelReports',
        inbox: 'downloadInboxReports',
        team: 'downloadTeamReports',
      };
      if (dispatchMethods[type]) {
        const fileName = generateFileName({ type, to, businessHours });
        const params = { from, to, fileName, businessHours };
        this.$store.dispatch(dispatchMethods[type], params);
      }
    },
    onDateRangeChange({ from, to, groupBy }) {
      // do not track filter change on inital load
      if (this.from !== 0 && this.to !== 0) {
        useTrack(REPORTS_EVENTS.FILTER_REPORT, {
          filterType: 'date',
          reportType: this.type,
        });
      }

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

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterType: 'groupBy',
        filterValue: this.groupBy?.period,
        reportType: this.type,
      });
    },
    fetchFilterItems(groupBy) {
      switch (groupBy) {
        case GROUP_BY_FILTER[2].period:
          return GROUP_BY_OPTIONS.WEEK.map(this.translateOptions);
        case GROUP_BY_FILTER[3].period:
          return GROUP_BY_OPTIONS.MONTH.map(this.translateOptions);
        case GROUP_BY_FILTER[4].period:
          return GROUP_BY_OPTIONS.YEAR.map(this.translateOptions);
        default:
          return GROUP_BY_OPTIONS.DAY.map(this.translateOptions);
      }
    },
    translateOptions(opts) {
      return { id: opts.id, groupBy: this.$t(opts.groupByKey) };
    },
    onBusinessHoursToggle(value) {
      this.businessHours = value;
      this.fetchAllData();

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterType: 'businessHours',
        filterValue: value,
        reportType: this.type,
      });
    },
  },
};
</script>

<template>
  <ReportHeader :header-title="reportTitle" :has-back-button="hasBackButton">
    <V4Button
      :label="downloadButtonLabel"
      icon="i-ph-download-simple"
      size="sm"
      @click="downloadReports"
    />
  </ReportHeader>
  <ReportFilters
    v-if="filterItemsList"
    :type="type"
    :filter-items-list="filterItemsList"
    :group-by-filter-items-list="groupByfilterItemsList"
    :selected-group-by-filter="selectedGroupByFilter"
    :current-filter="selectedFilter"
    @date-range-change="onDateRangeChange"
    @filter-change="onFilterChange"
    @group-by-filter-change="onGroupByFilterChange"
    @business-hours-toggle="onBusinessHoursToggle"
  />
  <ReportContainer
    v-if="filterItemsList.length"
    :group-by="groupBy"
    :report-keys="reportKeys"
  />
</template>
