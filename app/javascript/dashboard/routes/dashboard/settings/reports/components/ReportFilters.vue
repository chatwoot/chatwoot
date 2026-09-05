<script>
import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

import { GROUP_BY_FILTER } from '../constants';
const CUSTOM_DATE_RANGE_ID = 6;

export default {
  components: {
    WootDateRangePicker,
    ToggleSwitch,
  },
  props: {
    currentFilter: {
      type: Object,
      default: () => null,
    },
    filterItemsList: {
      type: Array,
      default: () => [],
    },
    groupByFilterItemsList: {
      type: Array,
      default: () => [],
    },
    type: {
      type: String,
      default: 'agent',
    },
    selectedGroupByFilter: {
      type: Object,
      default: () => {},
    },
  },
  emits: [
    'businessHoursToggle',
    'dateRangeChange',
    'filterChange',
    'groupByFilterChange',
  ],
  data() {
    return {
      currentSelectedFilter: this.currentFilter || null,
      currentDateRangeSelection: {
        id: 0,
        name: this.$t('REPORT.DATE_RANGE_OPTIONS.TODAY'),
      },
      customDateRange: [new Date(), new Date()],
      currentSelectedGroupByFilter: null,
      businessHoursSelected: false,
    };
  },
  computed: {
    dateRange() {
      return [
        { id: 0, name: this.$t('REPORT.DATE_RANGE_OPTIONS.TODAY') },
        { id: 1, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_7_DAYS') },
        { id: 2, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_30_DAYS') },
        { id: 3, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_3_MONTHS') },
        { id: 4, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_6_MONTHS') },
        { id: 5, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_YEAR') },
        { id: 6, name: this.$t('REPORT.DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE') },
      ];
    },
    isDateRangeSelected() {
      return this.currentDateRangeSelection.id === CUSTOM_DATE_RANGE_ID;
    },
    isTodaySelected() {
      return this.currentDateRangeSelection.id === 0;
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
      if (this.currentDateRangeSelection.id === 0) {
        return this.fromCustomDate(new Date());
      }
      const dateRange = { 1: 6, 2: 29, 3: 89, 4: 179, 5: 364 };
      const diff = dateRange[this.currentDateRangeSelection.id];
      const fromDate = subDays(new Date(), diff);
      return this.fromCustomDate(fromDate);
    },
    multiselectLabel() {
      const typeLabels = {
        agent: this.$t('AGENT_REPORTS.FILTER_DROPDOWN_LABEL'),
        label: this.$t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL'),
        inbox: this.$t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL'),
        team: this.$t('TEAM_REPORTS.FILTER_DROPDOWN_LABEL'),
      };
      return typeLabels[this.type] || this.$t('FORMS.MULTISELECT.SELECT_ONE');
    },
    groupBy() {
      if (this.isDateRangeSelected) {
        return GROUP_BY_FILTER[4]?.period || 'day';
      }
      if (this.currentDateRangeSelection.id === 0) {
        return GROUP_BY_FILTER[5]?.period || 'hour';
      }
      const groupRange = {
        1: GROUP_BY_FILTER[1]?.period,
        2: GROUP_BY_FILTER[2]?.period,
        3: GROUP_BY_FILTER[3]?.period,
        4: GROUP_BY_FILTER[3]?.period,
        5: GROUP_BY_FILTER[4]?.period,
      };
      return groupRange[this.currentDateRangeSelection.id] || 'day';
    },
    notLast7Days() {
      return this.groupBy !== GROUP_BY_FILTER[1]?.period;
    },
    showGroupByFilter() {
      return !this.isTodaySelected && this.notLast7Days;
    },
    selectedFilterId() {
      return this.currentSelectedFilter?.id ?? null;
    },
    selectedDateRangeId() {
      return this.currentDateRangeSelection.id;
    },
    selectedGroupById() {
      return this.currentSelectedGroupByFilter?.id ?? null;
    },
  },
  watch: {
    filterItemsList(val) {
      this.currentSelectedFilter = !this.currentFilter
        ? val[0]
        : this.currentFilter;
      this.changeFilterSelection();
    },
    groupByFilterItemsList() {
      this.currentSelectedGroupByFilter = this.selectedGroupByFilter;
    },
  },
  mounted() {
    this.onDateRangeChange();
  },
  methods: {
    onDateRangeChange() {
      this.$emit('dateRangeChange', {
        from: this.from,
        to: this.to,
        groupBy: this.groupBy,
      });
    },
    onBusinessHoursToggle() {
      this.$emit('businessHoursToggle', this.businessHoursSelected);
    },
    fromCustomDate(date) {
      return getUnixTime(startOfDay(date));
    },
    toCustomDate(date) {
      return getUnixTime(endOfDay(date));
    },
    changeDateSelection(id) {
      const found = this.dateRange.find(d => d.id === Number(id));
      if (found) {
        this.currentDateRangeSelection = found;
        this.onDateRangeChange();
      }
    },
    changeFilterSelection() {
      this.$emit('filterChange', this.currentSelectedFilter);
    },
    onFilterSelectChange(id) {
      const found = this.filterItemsList.find(f => f.id === Number(id));
      if (found) {
        this.currentSelectedFilter = found;
        this.changeFilterSelection();
      }
    },
    onChange(value) {
      this.customDateRange = value;
      this.onDateRangeChange();
    },
    onGroupBySelectChange(id) {
      const found = this.groupByFilterItemsList.find(f => f.id === Number(id));
      if (found) {
        this.currentSelectedGroupByFilter = found;
        this.$emit('groupByFilterChange', found);
      }
    },
  },
};
</script>

<template>
  <div class="grid grid-cols-1 md:grid-cols-3 gap-y-0.5 gap-x-2">
    <!-- Agent filter -->
    <div v-if="type === 'agent'">
      <p class="mb-2 text-xs font-medium">
        {{ $t('AGENT_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <select
        :value="selectedFilterId"
        class="no-margin"
        @change="e => onFilterSelectChange(e.target.value)"
      >
        <option v-for="item in filterItemsList" :key="item.id" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </div>

    <!-- Label filter -->
    <div v-else-if="type === 'label'">
      <p class="mb-2 text-xs font-medium">
        {{ $t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <select
        :value="selectedFilterId"
        class="no-margin"
        @change="e => onFilterSelectChange(e.target.value)"
      >
        <option v-for="item in filterItemsList" :key="item.id" :value="item.id">
          {{ item.title }}
        </option>
      </select>
    </div>

    <!-- Inbox / Team filter -->
    <div v-else>
      <p class="mb-2 text-xs font-medium">
        <template v-if="type === 'inbox'">
          {{ $t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL') }}
        </template>
        <template v-else-if="type === 'team'">
          {{ $t('TEAM_REPORTS.FILTER_DROPDOWN_LABEL') }}
        </template>
        <template v-else>
          {{ $t('FORMS.MULTISELECT.SELECT_ONE') }}
        </template>
      </p>
      <select
        :value="selectedFilterId"
        class="no-margin"
        @change="e => onFilterSelectChange(e.target.value)"
      >
        <option v-for="item in filterItemsList" :key="item.id" :value="item.id">
          {{ item.name }}
        </option>
      </select>
    </div>

    <!-- Date range -->
    <div>
      <p class="mb-2 text-xs font-medium">
        {{ $t('REPORT.DURATION_FILTER_LABEL') }}
      </p>
      <select
        :value="selectedDateRangeId"
        class="no-margin"
        @change="e => changeDateSelection(e.target.value)"
      >
        <option v-for="d in dateRange" :key="d.id" :value="d.id">
          {{ d.name }}
        </option>
      </select>
    </div>

    <!-- Business hours toggle -->
    <div
      class="flex items-center h-10 self-center order-5 md:order-2 md:justify-self-end"
    >
      <span class="mr-2 text-sm whitespace-nowrap">
        {{ $t('REPORT.BUSINESS_HOURS') }}
      </span>
      <ToggleSwitch
        v-model="businessHoursSelected"
        @change="onBusinessHoursToggle"
      />
    </div>

    <!-- Custom date range picker -->
    <div v-if="isDateRangeSelected" class="order-3 md:order-4">
      <p class="mb-2 text-xs font-medium">
        {{ $t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER') }}
      </p>
      <WootDateRangePicker
        show-range
        :value="customDateRange"
        :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
        :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
        class="auto-width"
        @change="onChange"
      />
    </div>

    <!-- Group by filter -->
    <div v-if="showGroupByFilter" class="order-4 md:order-5">
      <p class="mb-2 text-xs font-medium">
        {{ $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL') }}
      </p>
      <select
        :value="selectedGroupById"
        class="no-margin"
        @change="e => onGroupBySelectChange(e.target.value)"
      >
        <option
          v-for="item in groupByFilterItemsList"
          :key="item.id"
          :value="item.id"
        >
          {{ item.groupBy }}
        </option>
      </select>
    </div>
  </div>
</template>
