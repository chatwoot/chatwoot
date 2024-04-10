<template>
  <div class="flex flex-col md:flex-row justify-between mb-4">
    <div class="md:grid flex flex-col filter-container gap-3 w-full">
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
    </div>
  </div>
</template>
<script>
import WootDateRangePicker from 'dashboard/components/ui/DateRangePicker.vue';
import ReportsFiltersDateRange from '../Filters/DateRange.vue';
import subDays from 'date-fns/subDays';
import { DATE_RANGE_OPTIONS } from '../../constants';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';

export default {
  components: {
    WootDateRangePicker,
    ReportsFiltersDateRange,
  },

  data() {
    return {
      selectedDateRange: DATE_RANGE_OPTIONS.LAST_7_DAYS,
      selectedGroupByFilter: null,
      customDateRange: [new Date(), new Date()],
    };
  },
  computed: {
    isDateRangeSelected() {
      return (
        this.selectedDateRange.id === DATE_RANGE_OPTIONS.CUSTOM_DATE_RANGE.id
      );
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
      const { from, to } = this;
      this.$emit('filter-change', {
        from,
        to,
      });
    },
    onDateRangeChange(selectedRange) {
      this.selectedDateRange = selectedRange;
      this.emitChange();
    },
    onCustomDateRangeChange(value) {
      this.customDateRange = value;
      this.emitChange();
    },
  },
};
</script>

<style scoped>
.filter-container {
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
}
</style>
