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
      :limit-range="69"
      @date-range-change="onDateRangeChange"
      @filter-change="onFilterChange"
      @group-by-filter-change="onGroupByFilterChange"
      @business-hours-toggle="onBusinessHoursToggle"
    />

    <div
      v-if="!insightsEnabled"
      class="w-full flex items-center justify-center mt-12"
    >
      <templateInsightWall />
    </div>
    <div v-else>
      <div
        v-if="templateSummary"
        class="flex-col lg:flex-row flex flex-wrap mx-0 bg-white dark:bg-slate-800 rounded-[4px] p-4 mb-5 border border-solid border-slate-75 dark:border-slate-700"
      >
        <csat-metric-card
          :label="$t('TEMPLATE_REPORTS.METRICS.AMOUNT_SPEND.NAME')"
          :info-text="$t('TEMPLATE_REPORTS.METRICS.AMOUNT_SPEND.TOOLTIP')"
          :value="convertToMoney(templateSummary.amount_spent)"
          class="xs:w-full sm:max-w-[50%] lg:w-1/6 lg:max-w-[22%]"
        />
        <csat-metric-card
          :label="$t('TEMPLATE_REPORTS.METRICS.COST_PER_MESSAGE.NAME')"
          :info-text="$t('TEMPLATE_REPORTS.METRICS.COST_PER_MESSAGE.TOOLTIP')"
          :value="convertToMoney(templateSummary.cost_per_message_delivered)"
          class="xs:w-full sm:max-w-[50%] lg:w-[21%] lg:max-w-[22%]"
        />
        <csat-metric-card
          :label="$t('TEMPLATE_REPORTS.METRICS.COST_PER_BUTTON.NAME')"
          :info-text="$t('TEMPLATE_REPORTS.METRICS.COST_PER_BUTTON.TOOLTIP')"
          :value="convertToMoney(templateSummary.cost_per_website_button_click)"
          class="xs:w-full sm:max-w-[50%] lg:w-[22%] lg:max-w-[22%]"
        />
      </div>
      <report-template-container
        v-if="filterItemsList.length"
        :group-by="groupBy"
      />
    </div>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import ReportFilters from './ReportFilters.vue';
import ReportTemplateContainer from '../ReportTemplateContainer.vue';
import { GROUP_BY_FILTER } from '../constants';
import reportMixin from '../../../../../mixins/reportMixin';
import { generateFileName } from '../../../../../helper/downloadHelper';
import { REPORTS_EVENTS } from '../../../../../helper/AnalyticsHelper/events';
import CsatMetricCard from './ReportMetricCard.vue';
import templateInsightWall from './templates/templateInsightWall.vue';

const REPORTS_KEYS = {
  MESSAGES_SENT: 'messages_sent',
  MESSAGES_DELIVERED: 'messages_delivered',
  MESSAGES_READ: 'messages_read',
};

export default {
  components: {
    ReportFilters,
    ReportTemplateContainer,
    CsatMetricCard,
    templateInsightWall,
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
      insightsEnabled: true,
    };
  },
  computed: {
    filterItemsList() {
      return this.$store.getters[this.getterKey] || [];
    },
    templateReportChange() {
      return this.templateReport;
    },
  },
  mounted() {
    this.$store.dispatch(this.actionKey);
  },

  watch: {
    templateReport: {
      handler(newValue) {
        if (newValue) {
          this.verifyErrors();
        }
      },
      immediate: true,
      deep: true,
    },
  },

  methods: {
    async fetchAllData() {
      if (this.selectedFilter) {
        const { from, to, groupBy, businessHours } = this;
        try {
          await this.$store.dispatch('fetchTemplateSummary', {
            from,
            to,
            type: this.type,
            id: this.selectedFilter.id,
            groupBy: groupBy.period,
            businessHours,
            channelId: this.selectedFilter.channelId,
          });
        } catch (error) {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        } finally {
          this.fetchChartData();
        }
      }
    },
    fetchChartData() {
      const metrics = ['MESSAGES_SENT', 'MESSAGES_DELIVERED', 'MESSAGES_READ'];
      metrics.forEach(async key => {
        const { from, to, groupBy, businessHours } = this;
        try {
          await this.$store.dispatch('fetchTemplateReport', {
            metric: REPORTS_KEYS[key],
            from,
            to,
            type: this.type,
            id: this.selectedFilter.id,
            groupBy: groupBy.period,
            businessHours,
            channelId: this.selectedFilter.channelId,
          });
        } catch (error) {
          useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
        }
      });
    },

    downloadReports() {
      const { from, to, type, businessHours } = this;

      const filteredSummary = Object.keys(this.templateSummary)
        .filter(key => key !== 'previous')
        .reduce(
          (acc, key) => ({ ...acc, [key]: this.templateSummary[key] }),
          {}
        );

      const fileName = generateFileName({ type, to, businessHours });
      const params = {
        from,
        to,
        fileName,
        businessHours,
        summary: filteredSummary,
      };

      this.$store.dispatch('downloadTemplateReports', params);
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

    convertToMoney(value) {
      return 'US$ ' + parseFloat(value).toString();
    },

    verifyErrors() {
      if (this.templateReport.error === 'Template Insights not enabled') {
        this.insightsEnabled = false;
      } else if (this.templateReport.error) {
        this.insightsEnabled = true;
        useAlert(this.$t('REPORT.DATA_FETCHING_FAILED'));
      } else {
        this.insightsEnabled = true;
      }
    },
  },
};
</script>
