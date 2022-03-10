<template>
  <div class="flex-container flex-dir-column medium-flex-dir-row">
    <div class="small-12 medium-3 pull-right">
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
    <woot-date-range-picker
      v-if="isDateRangeSelected"
      show-range
      :value="customDateRange"
      :confirm-text="$t('REPORT.CUSTOM_DATE_RANGE.CONFIRM')"
      :placeholder="$t('REPORT.CUSTOM_DATE_RANGE.PLACEHOLDER')"
      @change="onChange"
    />
    <div
      v-if="notLast7Days && groupByFilter"
      class="small-12 medium-3 pull-right margin-left-small"
    >
      <p aria-hidden="true" class="hide">
        {{ $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL') }}
      </p>
      <multiselect
        v-model="currentSelectedFilter"
        track-by="id"
        label="groupBy"
        :placeholder="$t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')"
        :options="filterItemsList"
        :allow-empty="false"
        :show-labels="false"
        @input="changeFilterSelection"
      />
    </div>
    <div
      v-if="agentsFilter"
      class="small-12 medium-3 pull-right margin-left-small"
    >
      <multiselect
        v-model="selectedAgents"
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
  </div>
</template>
<script>
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
const CUSTOM_DATE_RANGE_ID = 5;
import subDays from 'date-fns/subDays';
import startOfDay from 'date-fns/startOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import { GROUP_BY_FILTER } from '../constants';
import endOfDay from 'date-fns/endOfDay';
import differenceInCalendarDays from 'date-fns/differenceInCalendarDays';

export default {
  components: {
    WootDateRangePicker,
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
  },
  data() {
    return {
      currentDateRangeSelection: this.$t('REPORT.DATE_RANGE')[0],
      dateRange: this.$t('REPORT.DATE_RANGE'),
      customDateRange: [new Date(), new Date()],
      currentSelectedFilter: null,
      selectedAgents: [],
    };
  },
  computed: {
    isDateRangeSelected() {
      return this.currentDateRangeSelection.id === CUSTOM_DATE_RANGE_ID;
    },
    currentDateRange() {
      let dateRange = {
        from: null,
        to: null,
      };
      if (this.isDateRangeSelected) {
        dateRange.from = this.fromCustomDate(this.customDateRange[0]);
        dateRange.to = this.toCustomDate(this.customDateRange[1]);
      } else {
        const fromDate = subDays(
          new Date(),
          this.daysRange(this.currentDateRangeSelection.id)
        );

        dateRange.from = this.fromCustomDate(fromDate);
        dateRange.to = this.toCustomDate(new Date());
      }
      return dateRange;
    },
    previousDateRange() {
      let dateRange = {
        from: null,
        to: null,
      };
      if (this.isDateRangeSelected) {
        const daysCount = differenceInCalendarDays(
          this.customDateRange[1],
          this.customDateRange[0]
        );
        const fromDate = subDays(new Date(), daysCount * 2);
        const toDate = subDays(new Date(), daysCount);
        dateRange.from = this.fromCustomDate(fromDate);
        dateRange.to = this.toCustomDate(toDate);
      } else {
        const fromDate = subDays(
          new Date(),
          this.daysRange(this.currentDateRangeSelection.id) * 2
        );
        const toDate = subDays(
          new Date(),
          this.daysRange(this.currentDateRangeSelection.id)
        );
        dateRange.from = this.fromCustomDate(fromDate);
        dateRange.to = this.toCustomDate(toDate);
      }
      return dateRange;
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
        4: GROUP_BY_FILTER[3].period,
      };
      return groupRange[this.currentDateRangeSelection.id];
    },
    notLast7Days() {
      return this.groupBy !== GROUP_BY_FILTER[1].period;
    },
  },
  watch: {
    filterItemsList() {
      this.currentSelectedFilter = this.selectedGroupByFilter;
    },
  },
  mounted() {
    this.onDateRangeChange();
  },
  methods: {
    onDateRangeChange() {
      this.$emit('date-range-change', {
        currentDateRange: this.currentDateRange,
        previousDateRange: this.previousDateRange,
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
    daysRange(currentDateRangeId) {
      const dateRange = {
        0: 6,
        1: 29,
        2: 89,
        3: 179,
        4: 364,
      };
      return dateRange[currentDateRangeId];
    },
    handleAgentsFilterSelection() {
      this.$emit('agents-filter-change', this.selectedAgents);
    },
  },
};
</script>

<style lang="scss" scoped>
.date-picker {
  margin-left: var(--space-smaller);
}
</style>
