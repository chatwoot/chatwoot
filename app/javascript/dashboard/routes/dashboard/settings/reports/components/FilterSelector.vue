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
    <reports-filters-date-group-by
      v-if="groupByFilter && isGroupByPossible"
      :valid-group-options="validGroupOptions"
      :selected-option="selectedGroupByFilter"
      @on-grouping-change="changeFilterSelection"
    />
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
import { DATE_RANGE_OPTIONS } from '../constants';
import ReportsFiltersDateGroupBy from './Filters/DateGroupBy.vue';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';

export default {
  components: {
    WootDateRangePicker,
    ReportsFiltersDateRange,
    ReportsFiltersDateGroupBy,
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
      selectedDateRange: DATE_RANGE_OPTIONS.LAST_7_DAYS,
      selectedGroupByFilter: null,
      customDateRange: [new Date(), new Date()],
      selectedAgents: [],
      businessHoursSelected: false,
    };
  },
  computed: {
    isDateRangeSelected() {
      return (
        this.selectedDateRange.id === DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE.id
      );
    },
    isGroupByPossible() {
      return this.selectedDateRange.id !== DATE_RANGE_OPTIONS.LAST_7_DAYS.id;
    },
    to() {
      if (this.isDateRangeSelected) {
        return getUnixEndOfDay(this.customDateRange[1]);
      }
      return getUnixEndOfDay(new Date());
    },
    from() {
      if (this.isDateRangeSelected) {
        return getUnixStartOfDay(this.customDateRange[0]);
      }

      const { offset } = this.selectedDateRange;
      const fromDate = subDays(new Date(), offset);
      return getUnixStartOfDay(fromDate);
    },
    validGroupOptions() {
      return this.selectedDateRange.groupByOptions;
    },
  },
  watch: {
    businessHoursSelected() {
      this.emitChange();
    },
  },
  mounted() {
    this.emitChange();
  },
  methods: {
    emitChange() {
      const {
        from,
        to,
        selectedGroupByFilter: groupBy,
        businessHoursSelected: businessHours,
      } = this;
      this.$emit('filter-change', { from, to, groupBy, businessHours });
    },
    validGroupBy() {
      if (!this.selectedGroupByFilter) {
        return this.validGroupOptions[0];
      }

      const validIds = this.validGroupOptions.map(opt => opt.id);
      if (validIds.includes(this.selectedGroupByFilter.id)) {
        return this.selectedGroupByFilter;
      }
      return this.validGroupOptions[0];
    },
    changeDateSelection(selectedRange) {
      this.selectedDateRange = selectedRange;
      this.selectedGroupByFilter = this.validGroupBy();
      this.emitChange();
    },
    onChange(value) {
      this.customDateRange = value;
      this.selectedGroupByFilter = this.validGroupBy();
      this.emitChange();
    },
    changeFilterSelection(payload) {
      this.selectedGroupByFilter = payload;
      this.emitChange();
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
