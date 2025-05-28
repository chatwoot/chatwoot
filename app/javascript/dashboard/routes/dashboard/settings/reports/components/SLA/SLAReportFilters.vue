<script>
import SLAFilter from '../SLA/SLAFilter.vue';
import subDays from 'date-fns/subDays';
import { DATE_RANGE_OPTIONS } from '../../constants';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';

export default {
  components: {
    SLAFilter,
  },
  emits: ['filterChange'],

  data() {
    return {
      selectedDateRange: DATE_RANGE_OPTIONS.LAST_7_DAYS,
      selectedGroupByFilter: null,
      customDateRange: [new Date(), new Date()],
    };
  },
  computed: {
    to() {
      return getUnixEndOfDay(this.customDateRange[1]);
    },
    from() {
      return getUnixStartOfDay(this.customDateRange[0]);
    },
  },
  watch: {
    businessHoursSelected() {
      this.emitChange();
    },
  },
  mounted() {
    this.setInitialRange();
  },
  methods: {
    setInitialRange() {
      const { offset } = this.selectedDateRange;
      const fromDate = subDays(new Date(), offset);
      const from = getUnixStartOfDay(fromDate);
      const to = getUnixEndOfDay(new Date());
      this.$emit('filterChange', {
        from,
        to,
        ...this.selectedGroupByFilter,
      });
    },
    emitChange() {
      const { from, to } = this;
      this.$emit('filterChange', {
        from,
        to,
        ...this.selectedGroupByFilter,
      });
    },
    emitFilterChange(params) {
      this.selectedGroupByFilter = params;
      this.emitChange();
    },
    onDateRangeChange(value) {
      this.customDateRange = value;
      this.emitChange();
    },
  },
};
</script>

<template>
  <div class="flex flex-col flex-wrap w-full gap-3 md:flex-row">
    <woot-date-picker @date-range-changed="onDateRangeChange" />
    <SLAFilter @filter-change="emitFilterChange" />
  </div>
</template>
