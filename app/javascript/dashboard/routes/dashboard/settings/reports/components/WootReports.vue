<script>
import V4Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';
import ReportFilters from './ReportFilters.vue';
import ReportContainer from '../ReportContainer.vue';
import { GROUP_BY_FILTER } from '../constants';
import { generateFileName } from '../../../../../helper/downloadHelper';
import ReportHeader from './ReportHeader.vue';

const GROUP_BY_OPTIONS = {
  HOUR: [{ id: 5, groupByKey: 'REPORT.GROUPING_OPTIONS.HOUR' }],
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
      businessHours: false,
    };
  },
  computed: {
    filterType() {
      const pluralMap = {
        agent: 'agents',
        team: 'teams',
        inbox: 'inboxes',
        label: 'labels',
      };
      return pluralMap[this.type] || this.type;
    },
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
        ...(this.isAgentType
          ? { AGENT_CHAT_DURATION: 'agent_chat_duration' }
          : {}),
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
      if (this.from !== 0 && this.to !== 0) {
        useTrack(REPORTS_EVENTS.FILTER_REPORT, {
          filterType: 'date',
          reportType: this.type,
        });
      }

      this.from = from;
      this.to = to;
      this.businessHours = businessHours;

      if (groupBy) {
        this.groupBy = groupBy;
      } else {
        this.groupBy = GROUP_BY_FILTER[1];
      }

      useTrack(REPORTS_EVENTS.FILTER_REPORT, {
        filterType: 'groupBy',
        filterValue: this.groupBy?.period,
        reportType: this.type,
      });
    },
    fetchFilterItems(groupBy) {
      switch (groupBy) {
        case GROUP_BY_FILTER[5].period:
          return GROUP_BY_OPTIONS.HOUR.map(this.translateOptions);
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
      const translations = {
        'REPORT.GROUPING_OPTIONS.HOUR': this.$t('REPORT.GROUPING_OPTIONS.HOUR'),
        'REPORT.GROUPING_OPTIONS.DAY': this.$t('REPORT.GROUPING_OPTIONS.DAY'),
        'REPORT.GROUPING_OPTIONS.WEEK': this.$t('REPORT.GROUPING_OPTIONS.WEEK'),
        'REPORT.GROUPING_OPTIONS.MONTH': this.$t(
          'REPORT.GROUPING_OPTIONS.MONTH'
        ),
        'REPORT.GROUPING_OPTIONS.YEAR': this.$t('REPORT.GROUPING_OPTIONS.YEAR'),
      };

      return {
        id: opts.id,
        groupBy: translations[opts.groupByKey] || opts.groupByKey,
      };
    },
    onBusinessHoursToggle(value) {
      this.businessHours = value;
      this.fetchAllData();

      this.fetchAllData();
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
    :filter-type="filterType"
    :selected-item="selectedFilter"
    @filter-change="onFilterChange"
  />
  <ReportContainer
    v-if="filterItemsList.length"
    :group-by="groupBy"
    :report-keys="reportKeys"
  />
</template>
