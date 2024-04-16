<template>
  <div class="flex flex-col justify-between gap-3 mb-4 md:flex-row">
    <div
      class="w-full grid gap-y-2 gap-x-1.5 grid-cols-[repeat(auto-fill,minmax(250px,1fr))]"
    >
      <reports-filters-date-range @on-range-change="onDateRangeChange" />
      <woot-date-range-picker
        v-if="isDateRangeSelected"
        show-range
        class="no-margin auto-width"
        :value="customDateRange"
        :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
        :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
        @change="onCustomDateRangeChange"
      />
      <reports-filters-date-group-by
        v-if="showGroupByFilter && isGroupByPossible"
        :valid-group-options="validGroupOptions"
        :selected-option="selectedGroupByFilter"
        @on-grouping-change="onGroupingChange"
      />
      <reports-filters-agents
        v-if="showAgentsFilter"
        @agents-filter-selection="handleAgentsFilterSelection"
      />
      <reports-filters-labels
        v-if="showLabelsFilter"
        @labels-filter-selection="handleLabelsFilterSelection"
      />
      <reports-filters-teams
        v-if="showTeamFilter"
        @team-filter-selection="handleTeamFilterSelection"
      />
      <reports-filters-inboxes
        v-if="showInboxFilter"
        @inbox-filter-selection="handleInboxFilterSelection"
      />
      <reports-filters-ratings
        v-if="showRatingFilter"
        @rating-filter-selection="handleRatingFilterSelection"
      />
    </div>
    <div v-if="showBusinessHoursSwitch" class="flex items-center">
      <span class="mx-2 text-sm whitespace-nowrap">
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
import ReportsFiltersDateGroupBy from './Filters/DateGroupBy.vue';
import ReportsFiltersAgents from './Filters/Agents.vue';
import ReportsFiltersLabels from './Filters/Labels.vue';
import ReportsFiltersInboxes from './Filters/Inboxes.vue';
import ReportsFiltersTeams from './Filters/Teams.vue';
import ReportsFiltersRatings from './Filters/Ratings.vue';
import subDays from 'date-fns/subDays';
import { DATE_RANGE_OPTIONS } from '../constants';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';

export default {
  components: {
    WootDateRangePicker,
    ReportsFiltersDateRange,
    ReportsFiltersDateGroupBy,
    ReportsFiltersAgents,
    ReportsFiltersLabels,
    ReportsFiltersInboxes,
    ReportsFiltersTeams,
    ReportsFiltersRatings,
  },
  props: {
    filterItemsList: {
      type: Array,
      default: () => [],
    },
    showGroupByFilter: {
      type: Boolean,
      default: false,
    },
    showAgentsFilter: {
      type: Boolean,
      default: false,
    },
    showLabelsFilter: {
      type: Boolean,
      default: false,
    },
    showInboxFilter: {
      type: Boolean,
      default: false,
    },
    showRatingFilter: {
      type: Boolean,
      default: false,
    },
    showTeamFilter: {
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
      selectedLabel: null,
      selectedInbox: null,
      selectedTeam: null,
      selectedRating: null,
      selectedAgents: [],
      customDateRange: [new Date(), new Date()],
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
        selectedAgents,
        selectedLabel,
        selectedInbox,
        selectedTeam,
        selectedRating,
      } = this;
      this.$emit('filter-change', {
        from,
        to,
        groupBy,
        businessHours,
        selectedAgents,
        selectedLabel,
        selectedInbox,
        selectedTeam,
        selectedRating,
      });
    },
    onDateRangeChange(selectedRange) {
      this.selectedDateRange = selectedRange;
      this.selectedGroupByFilter = this.validGroupBy;
      this.emitChange();
    },
    onCustomDateRangeChange(value) {
      this.customDateRange = value;
      this.selectedGroupByFilter = this.validGroupBy;
      this.emitChange();
    },
    onGroupingChange(payload) {
      this.selectedGroupByFilter = payload;
      this.emitChange();
    },
    handleAgentsFilterSelection(selectedAgents) {
      this.selectedAgents = selectedAgents;
      this.emitChange();
    },
    handleLabelsFilterSelection(selectedLabel) {
      this.selectedLabel = selectedLabel;
      this.emitChange();
    },
    handleInboxFilterSelection(selectedInbox) {
      this.selectedInbox = selectedInbox;
      this.emitChange();
    },
    handleTeamFilterSelection(selectedTeam) {
      this.selectedTeam = selectedTeam;
      this.emitChange();
    },
    handleRatingFilterSelection(selectedRating) {
      this.selectedRating = selectedRating;
      this.emitChange();
    },
  },
};
</script>
