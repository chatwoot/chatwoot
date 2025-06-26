<script>
import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';

import { GROUP_BY_FILTER } from '../constants';
const CUSTOM_DATE_RANGE_ID = 5;

export default {
  components: {
    WootDateRangePicker,
    Thumbnail,
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
        name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_7_DAYS'),
      },
      customDateRange: [new Date(), new Date()],
      currentSelectedGroupByFilter: null,
      businessHoursSelected: false,
    };
  },
  computed: {
    dateRange() {
      return [
        { id: 0, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_7_DAYS') },
        { id: 1, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_30_DAYS') },
        { id: 2, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_3_MONTHS') },
        { id: 3, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_6_MONTHS') },
        { id: 4, name: this.$t('REPORT.DATE_RANGE_OPTIONS.LAST_YEAR') },
        { id: 5, name: this.$t('REPORT.DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE') },
      ];
    },
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
      const dateRange = {
        0: 6,
        1: 29,
        2: 89,
        3: 179,
        4: 364,
      };
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
        return GROUP_BY_FILTER[4].period;
      }
      const groupRange = {
        0: GROUP_BY_FILTER[1].period,
        1: GROUP_BY_FILTER[2].period,
        2: GROUP_BY_FILTER[3].period,
        3: GROUP_BY_FILTER[3].period,
        4: GROUP_BY_FILTER[4].period,
      };
      return groupRange[this.currentDateRangeSelection.id];
    },
    notLast7Days() {
      return this.groupBy !== GROUP_BY_FILTER[1].period;
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
    businessHoursSelected() {
      this.$emit('businessHoursToggle', this.businessHoursSelected);
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
    changeFilterSelection() {
      this.$emit('filterChange', this.currentSelectedFilter);
    },
    onChange(value) {
      this.customDateRange = value;
      this.onDateRangeChange();
    },
    changeGroupByFilterSelection() {
      this.$emit('groupByFilterChange', this.currentSelectedGroupByFilter);
    },
  },
};
</script>

<template>
  <div class="grid grid-cols-1 md:grid-cols-3 gap-y-0.5 gap-x-2">
    <div v-if="type === 'agent'" class="multiselect-wrap--small">
      <p class="mb-2 text-xs font-medium">
        {{ $t('AGENT_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        :placeholder="multiselectLabel"
        label="name"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @update:model-value="changeFilterSelection"
      >
        <template #singleLabel="props">
          <div class="flex min-w-0 items-center gap-2">
            <Thumbnail
              :src="props.option.thumbnail"
              :status="props.option.availability_status"
              :username="props.option.name"
              size="22px"
            />
            <span class="my-0 text-slate-800 truncate dark:text-slate-75">{{
              props.option.name
            }}</span>
          </div>
        </template>
        <template #options="props">
          <div class="flex items-center gap-2">
            <Thumbnail
              :src="props.option.thumbnail"
              :status="props.option.availability_status"
              :username="props.option.name"
              size="22px"
            />
            <p class="my-0 text-slate-800 dark:text-slate-75">
              {{ props.option.name }}
            </p>
          </div>
        </template>
      </multiselect>
    </div>

    <div v-else-if="type === 'label'" class="multiselect-wrap--small">
      <p class="mb-2 text-xs font-medium">
        {{ $t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        :placeholder="multiselectLabel"
        label="title"
        track-by="id"
        :options="filterItemsList"
        :option-height="24"
        :show-labels="false"
        @update:model-value="changeFilterSelection"
      >
        <template #singleLabel="props">
          <div class="flex items-center min-w-0 gap-2">
            <div
              :style="{ backgroundColor: props.option.color }"
              class="w-5 h-5 rounded-full"
            />

            <span class="my-0 text-slate-800 truncate dark:text-slate-75">
              {{ props.option.title }}
            </span>
          </div>
        </template>
        <template #option="props">
          <div class="flex items-center min-w-0 gap-2">
            <div
              :style="{ backgroundColor: props.option.color }"
              class="flex-shrink-0 w-5 h-5 border border-solid rounded-full border-slate-100 dark:border-slate-800"
            />

            <span class="my-0 text-slate-800 truncate dark:text-slate-75">
              {{ props.option.title }}
            </span>
          </div>
        </template>
      </multiselect>
    </div>

    <div v-else class="multiselect-wrap--small">
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
      <multiselect
        v-model="currentSelectedFilter"
        track-by="id"
        label="name"
        :placeholder="multiselectLabel"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        deselect-label=""
        :options="filterItemsList"
        :searchable="false"
        :allow-empty="false"
        @update:model-value="changeFilterSelection"
      />
    </div>

    <div class="multiselect-wrap--small">
      <p class="mb-2 text-xs font-medium">
        {{ $t('REPORT.DURATION_FILTER_LABEL') }}
      </p>
      <multiselect
        v-model="currentDateRangeSelection"
        track-by="name"
        label="name"
        :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
        selected-label
        :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
        deselect-label=""
        :options="dateRange"
        :searchable="false"
        :allow-empty="false"
        @select="changeDateSelection"
      />
    </div>

    <div
      class="flex items-center h-10 self-center order-5 md:order-2 md:justify-self-end"
    >
      <span class="mr-2 text-sm whitespace-nowrap">
        {{ $t('REPORT.BUSINESS_HOURS') }}
      </span>
      <span>
        <woot-switch v-model="businessHoursSelected" />
      </span>
    </div>

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

    <div v-if="notLast7Days" class="multiselect-wrap--small order-4 md:order-5">
      <p class="mb-2 text-xs font-medium">
        {{ $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedGroupByFilter"
        track-by="id"
        label="groupBy"
        :placeholder="$t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')"
        :options="groupByFilterItemsList"
        :allow-empty="false"
        :show-labels="false"
        @update:model-value="changeGroupByFilterSelection"
      />
    </div>
  </div>
</template>
