<template>
  <div class="flex-1 p-4 overflow-auto">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
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
      @business-hours-toggle="onBusinessHoursToggle"
    />
    <report-container v-if="filterItemsList.length" :group-by="groupBy" />
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import ReportFilters from './ReportFilters.vue';
import ReportContainer from '../ReportContainer.vue';
import { GROUP_BY_FILTER } from '../constants';
import reportMixin from '../../../../../mixins/reportMixin';
import { generateFileName } from '../../../../../helper/downloadHelper';
import { REPORTS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';

const REPORTS_KEYS = {
  CONVERSATIONS: 'conversations_count',
  INCOMING_MESSAGES: 'incoming_messages_count',
  OUTGOING_MESSAGES: 'outgoing_messages_count',
  FIRST_RESPONSE_TIME: 'avg_first_response_time',
  RESOLUTION_TIME: 'avg_resolution_time',
  RESOLUTION_COUNT: 'resolutions_count',
  REPLY_TIME: 'reply_time',
};

export default {
  components: {
    ReportFilters,
    ReportContainer,
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
      selectedFilter: null,
      groupBy: GROUP_BY_FILTER[1],
      groupByfilterItemsList: this.$t('REPORT.GROUP_BY_DAY_OPTIONS'),
      selectedGroupByFilter: null,
      businessHours: false,
    };
  },
  computed: {
    filterItemsList() {
      return this.$store.getters[this.getterKey] || [];
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
      [
        'CONVERSATIONS',
        'INCOMING_MESSAGES',
        'OUTGOING_MESSAGES',
        'FIRST_RESPONSE_TIME',
        'RESOLUTION_TIME',
        'RESOLUTION_COUNT',
        'REPLY_TIME',
      ].forEach(async key => {
        try {
          const { from, to, groupBy, businessHours } = this;
          this.$store.dispatch('fetchAccountReport', {
            metric: REPORTS_KEYS[key],
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
        this.$track(REPORTS_EVENTS.FILTER_REPORT, {
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

      this.$track(REPORTS_EVENTS.FILTER_REPORT, {
        filterType: 'groupBy',
        filterValue: this.groupBy?.period,
        reportType: this.type,
      });
    },
    fetchFilterItems(groupBy) {
      switch (groupBy) {
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
        reportType: this.type,
      });
    },
  },
};
</script>
