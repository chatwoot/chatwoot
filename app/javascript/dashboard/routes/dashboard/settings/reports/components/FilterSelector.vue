<template>
  <div class="filter-container">
    <reports-filters-date-range @on-range-change="changeDateSelection" />
    <woot-date-range-picker
      v-if="isDateRangeSelected"
      show-range
      :value="customDateRange"
      :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
      :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
      @change="onChange"
    />
    <div v-if="notLast7Days && groupByFilter" class="multiselect-wrap--small">
      <p aria-hidden="true" class="hide">
        {{ $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        class="no-margin"
        track-by="id"
        label="groupBy"
        :placeholder="$t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')"
        :options="filterItemsList"
        :allow-empty="false"
        :show-labels="false"
        @input="changeFilterSelection"
      />
    </div>
    <div v-if="agentsFilter" class="multiselect-wrap--small">
      <multiselect
        v-model="selectedAgents"
        class="no-margin"
        :options="agentsFilterItemsList"
        track-by="id"
        label="name"
        :multiple="true"
        :close-on-select="false"
        :clear-on-select="false"
        :hide-selected="true"
        :placeholder="$t('CSAT_REPORTS.FILTERS.AGENTS.PLACEHOLDER')"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
        @input="handleAgentsFilterSelection"
      />
    </div>
    <div v-if="showBusinessHoursSwitch" class="business-hours">
      <span class="business-hours-text ">
        {{ $t('REPORT.BUSINESS_HOURS') }}
      </span>
      <span>
        <woot-switch v-model="businessHoursSelected" />
      </span>
    </div>
  </div>
</template>
<script>
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
import ReportsFiltersDateRange from './Filters/DateRange.vue';
import subDays from 'date-fns/subDays';
import startOfDay from 'date-fns/startOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import { GROUP_BY_FILTER, DATE_RANGE_OPTIONS } from '../constants';
import endOfDay from 'date-fns/endOfDay';

const CUSTOM_DATE_RANGE_ID = DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE.id;

export default {
  components: {
    WootDateRangePicker,
    ReportsFiltersDateRange,
  },
  props: {
    filterItemsList: {
      type: Array,
      default: () => [],
    },
    agentsFilterItemsList: {
      type: Array,
      default: () => [],
    },
    selectedGroupByFilter: {
      type: Object,
      default: () => {},
    },
    groupByFilter: {
      type: Boolean,
      default: false,
    },
    agentsFilter: {
      type: Boolean,
      default: false,
    },
    showBusinessHoursSwitch: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      // default value, need not be translated
      currentDateRangeSelection: DATE_RANGE_OPTIONS.LAST_7_DAYS,
      customDateRange: [new Date(), new Date()],
      currentSelectedFilter: null,
      selectedAgents: [],
      businessHoursSelected: false,
    };
  },
  computed: {
    isDateRangeSelected() {
      return this.currentDateRangeSelection.id === CUSTOM_DATE_RANGE_ID;
    },
    to() {
      if (this.isDateRangeSelected) {
        return this.toCustomDate(this.customDateRange[1]);
      }
      return this.toCustomDate(new Date());
    },
    from() {
      if (this.isDateRangeSelected) {
        return this.fromCustomDate(this.customDateRange[0]);
      }

      const { offset } = this.currentDateRangeSelection;
      const fromDate = subDays(new Date(), offset);
      return this.fromCustomDate(fromDate);
    },
    groupBy() {
      return this.currentDateRangeSelection.groupBy;
    },
    notLast7Days() {
      return this.groupBy !== GROUP_BY_FILTER[1].period;
    },
  },
  watch: {
    filterItemsList() {
      this.currentSelectedFilter = this.selectedGroupByFilter;
    },
    businessHoursSelected() {
      this.$emit('business-hours-toggle', this.businessHoursSelected);
    },
  },
  mounted() {
    this.onDateRangeChange();
  },
  methods: {
    onDateRangeChange() {
      this.$emit('date-range-change', {
        from: this.from,
        to: this.to,
        groupBy: this.groupBy,
      });
    },
    fromCustomDate(date) {
      return getUnixTime(startOfDay(date));
    },
    toCustomDate(date) {
      return getUnixTime(endOfDay(date));
    },
    changeDateSelection(selectedRange) {
      this.currentDateRangeSelection = selectedRange;
      this.onDateRangeChange();
    },
    onChange(value) {
      this.customDateRange = value;
      this.onDateRangeChange();
    },
    changeFilterSelection() {
      this.$emit('filter-change', this.currentSelectedFilter);
    },
    handleAgentsFilterSelection() {
      this.$emit('agents-filter-change', this.selectedAgents);
    },
  },
};
</script>

<style scoped>
.filter-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 250px));
  grid-gap: 10px;

  margin-bottom: var(--space-normal);
}
</style>
