<template>
  <span class="timeago">
    <span> {{ timeago }}</span>
  </span>
</template>

<script>
const ZERO = 0;
const MINUTE_IN_MSEC = 60000;
const HOUR_IN_MSEC = MINUTE_IN_MSEC * 60;
const DAY_IN_MSEC = HOUR_IN_MSEC * 24;
const MONTH_IN_MSEC = DAY_IN_MSEC * 30;
const YEAR_IN_MSEC = MONTH_IN_MSEC * 12;

import timeMixin from 'dashboard/mixins/time';
import {
  differenceInMinutes,
  differenceInHours,
  differenceInDays,
  differenceInCalendarMonths,
  differenceInCalendarYears,
} from 'date-fns';

export default {
  name: 'TimeAgo',
  mixins: [timeMixin],
  props: {
    refresh: {
      type: Boolean,
      default: false,
    },
    timestamp: {
      type: [String, Date, Number],
      default: '',
    },
  },
  data() {
    return {
      timeago: '',
      timer: null,
    };
  },
  computed: {
    currentDate() {
      return new Date();
    },
    previousDate() {
      return new Date(this.timestamp * 1000);
    },

    hasMinutesDiff() {
      const minutes = differenceInMinutes(this.currentDate, this.previousDate);
      return minutes < 60;
    },
    hasHourDiff() {
      const hours = differenceInHours(this.currentDate, this.previousDate);
      return hours >= 1 && hours <= 24;
    },
    hasDayDiff() {
      const days = differenceInDays(this.currentDate, this.previousDate);
      return days >= 1 && days <= 31;
    },
    hasMonthDiff() {
      const months = differenceInCalendarMonths(
        this.currentDate,
        this.previousDate
      );
      return months >= 1 && months <= 6;
    },
    hasYearDiff() {
      const years = differenceInCalendarYears(
        this.currentDate,
        this.previousDate
      );
      return years >= 1;
    },
    refreshTime() {
      if (this.refresh === true) {
        if (this.hasMinutesDiff && !this.hasHourDiff) {
          return MINUTE_IN_MSEC;
        }
        if (this.hasHourDiff && !this.hasDayDiff) {
          return HOUR_IN_MSEC;
        }
        if (this.hasDayDiff && !this.hasMonthDiff) {
          return DAY_IN_MSEC;
        }
        if (this.hasMonthDiff && !this.hasYearDiff) {
          return MONTH_IN_MSEC;
        }
        if (this.hasYearDiff) {
          return YEAR_IN_MSEC;
        }
      }
      return ZERO;
    },
  },
  mounted() {
    this.createTimer();
  },
  beforeDestroy() {
    this.clearTimer();
  },
  methods: {
    createTimer() {
      this.timeago = this.dynamicTime(this.timestamp);
      this.$nextTick(() => {
        if (this.refresh === true) {
          const refreshTime = this.refreshTime;
          let timerValue = setTimeout(() => {
            this.timer = timerValue;
            this.timeago = this.dynamicTime(this.timestamp);
            timerValue = setTimeout(() => {
              this.createTimer();
            }, refreshTime);
          }, refreshTime);
        } else {
          this.timeago = this.dynamicTime(this.timestamp);
        }
      });
    },
    clearTimer() {
      if (this.timer) {
        clearTimeout(this.timer);
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.timeago {
  color: var(--b-600);
  font-size: var(--font-size-micro);
  font-weight: var(--font-weight-normal);
  line-height: var(--space-normal);
  margin-left: auto;
}
</style>
