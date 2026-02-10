<script>
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
import ReportsFiltersDateRange from './Filters/DateRange.vue';
import ReportsFiltersDateGroupBy from './Filters/DateGroupBy.vue';
import ReportsFiltersAgents from './Filters/Agents.vue';
import ReportsFiltersLabels from './Filters/Labels.vue';
import ReportsFiltersInboxes from './Filters/Inboxes.vue';
import ReportsFiltersTeams from './Filters/Teams.vue';
import ReportsFiltersRatings from './Filters/Ratings.vue';
import ReportsFiltersTimeRange from './Filters/TimeRange.vue';
import subDays from 'date-fns/subDays';
import { DATE_RANGE_OPTIONS, GROUP_BY_OPTIONS } from '../constants';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

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
    ReportsFiltersTimeRange,
    ToggleSwitch,
  },

  props: {
    showGroupByFilter: Boolean,
    showAgentsFilter: Boolean,
    showLabelsFilter: Boolean,
    showInboxFilter: Boolean,
    showRatingFilter: Boolean,
    showTeamFilter: Boolean,
    showBusinessHoursSwitch: {
      type: Boolean,
      default: true,
    },
    showTimeRangeFilter: Boolean,
  },

  emits: ['filterChange'],

  data() {
    const initialDateRange = DATE_RANGE_OPTIONS.TODAY;
    let initialGroupBy = null;

    if (
      initialDateRange.groupByOptions &&
      initialDateRange.groupByOptions.length > 0
    ) {
      if (initialDateRange.id === DATE_RANGE_OPTIONS.TODAY.id) {
        const hourOption = initialDateRange.groupByOptions.find(
          opt => opt.period === 'hour'
        );
        initialGroupBy = hourOption || initialDateRange.groupByOptions[0];
      } else {
        initialGroupBy = initialDateRange.groupByOptions[0];
      }
    }

    return {
      selectedDateRange: initialDateRange,
      selectedGroupByFilter: initialGroupBy,
      selectedLabel: null,
      selectedInbox: [],
      selectedTeam: [],
      selectedRating: null,
      selectedAgents: [],
      customDateRange: [new Date(), new Date()],
      businessHoursSelected: false,

      selectedTimeRange: {
        since: '00:00',
        until: '23:59',
      },
    };
  },

  computed: {
    isDateRangeSelected() {
      return (
        this.selectedDateRange.id === DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE.id
      );
    },

    isTodaySelected() {
      return this.selectedDateRange.id === DATE_RANGE_OPTIONS.TODAY.id;
    },

    isGroupByPossible() {
      return !this.isTodaySelected;
    },

    validGroupOptions() {
      if (this.isTodaySelected) {
        return [GROUP_BY_OPTIONS.HOUR];
      }
      return this.selectedDateRange.groupByOptions || [];
    },

    validGroupBy() {
      if (!this.validGroupOptions || !this.validGroupOptions.length) {
        return null;
      }
      if (!this.selectedGroupByFilter) {
        if (this.selectedDateRange.id === DATE_RANGE_OPTIONS.TODAY.id) {
          const hourOption = this.validGroupOptions.find(
            opt => opt.period === 'hour'
          );
          return hourOption || this.validGroupOptions[0];
        }
        return this.validGroupOptions[0];
      }

      const validIds = this.validGroupOptions.map(opt => opt.id);
      return validIds.includes(this.selectedGroupByFilter.id)
        ? this.selectedGroupByFilter
        : this.validGroupOptions[0];
    },

    hasOtherFilters() {
      return (
        this.showAgentsFilter ||
        this.showLabelsFilter ||
        this.showTeamFilter ||
        this.showInboxFilter ||
        this.showRatingFilter
      );
    },
  },

  mounted() {
    this.emitChange();
  },

  methods: {
    getUnixWithTime(date, time) {
      const [hours, minutes] = time.split(':').map(Number);

      const year = date.getFullYear();
      const month = date.getMonth();
      const day = date.getDate();
      const utcDate = new Date(
        Date.UTC(year, month, day, hours, minutes, 0, 0)
      );

      return Math.floor(utcDate.getTime() / 1000);
    },

    emitChange() {
      const startDate = this.isDateRangeSelected
        ? this.customDateRange[0]
        : subDays(new Date(), this.selectedDateRange.offset || 0);

      const endDate = this.isDateRangeSelected
        ? this.customDateRange[1]
        : new Date();

      const from = this.getUnixWithTime(
        startDate,
        this.selectedTimeRange.since
      );

      const to = this.getUnixWithTime(endDate, this.selectedTimeRange.until);

      this.$emit('filterChange', {
        from,
        to,
        groupBy: this.selectedGroupByFilter,
        businessHours: this.businessHoursSelected,
        selectedAgents: this.selectedAgents,
        selectedLabel: this.selectedLabel,
        selectedInbox: this.selectedInbox,
        selectedTeam: this.selectedTeam,
        selectedRating: this.selectedRating,
        timeRange: this.selectedTimeRange,
      });
    },

    onDateRangeChange(selectedRange) {
      this.selectedDateRange = selectedRange;

      if (selectedRange.id === DATE_RANGE_OPTIONS.TODAY.id) {
        if (this.validGroupOptions && this.validGroupOptions.length) {
          const hourOption = this.validGroupOptions.find(
            opt => opt.period === 'hour'
          );
          if (hourOption) {
            this.selectedGroupByFilter = hourOption;
          }
        }
      } else {
        this.selectedGroupByFilter = this.validGroupBy;
      }

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

    handleLabelsFilterSelection(selectedLabels) {
      this.selectedLabel = selectedLabels;
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

    handleTimeRangeChange(timeRange) {
      this.selectedTimeRange = timeRange;
      this.emitChange();
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex flex-col justify-between gap-3 md:flex-row">
      <div
        class="w-full grid gap-y-2 gap-x-1.5 grid-cols-[repeat(auto-fill,minmax(250px,1fr))]"
      >
        <ReportsFiltersDateRange @on-range-change="onDateRangeChange" />

        <WootDateRangePicker
          v-if="isDateRangeSelected"
          show-range
          class="no-margin auto-width"
          :value="customDateRange"
          :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
          :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
          @change="onCustomDateRangeChange"
        />

        <ReportsFiltersDateGroupBy
          v-if="showGroupByFilter && isGroupByPossible"
          :valid-group-options="validGroupOptions"
          :selected-option="selectedGroupByFilter"
          :selected-date-range="selectedDateRange"
          @on-grouping-change="onGroupingChange"
        />

        <ReportsFiltersTimeRange
          v-if="showTimeRangeFilter"
          @time-range-changed="handleTimeRangeChange"
        />
      </div>

      <div v-if="showBusinessHoursSwitch" class="flex items-center">
        <span class="mx-2 text-sm whitespace-nowrap">
          {{ $t('REPORT.BUSINESS_HOURS') }}
        </span>
        <ToggleSwitch v-model="businessHoursSelected" @change="emitChange" />
      </div>
    </div>

    <div
      v-if="hasOtherFilters"
      class="w-full grid gap-y-2 gap-x-1.5 grid-cols-[repeat(auto-fill,minmax(250px,1fr))]"
    >
      <ReportsFiltersAgents
        v-if="showAgentsFilter"
        @agents-filter-selection="handleAgentsFilterSelection"
      />

      <ReportsFiltersLabels
        v-if="showLabelsFilter"
        @labels-filter-selection="handleLabelsFilterSelection"
      />

      <ReportsFiltersTeams
        v-if="showTeamFilter"
        @team-filter-selection="handleTeamFilterSelection"
      />

      <ReportsFiltersInboxes
        v-if="showInboxFilter"
        @inbox-filter-selection="handleInboxFilterSelection"
      />

      <ReportsFiltersRatings
        v-if="showRatingFilter"
        @rating-filter-selection="handleRatingFilterSelection"
      />
    </div>
  </div>
</template>
