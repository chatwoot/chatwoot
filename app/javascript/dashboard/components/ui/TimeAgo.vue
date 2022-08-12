<template>
  <span class="timeago">
    <span> {{ timeago }}</span>
  </span>
</template>

<script>
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
      type: [Number, Boolean],
      default: false,
    },
    datetime: {
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
    hasMinutesDiff() {
      const today = new Date();
      const date = new Date(this.datetime * 1000);
      const minutes = differenceInMinutes(today, date);
      return minutes <= 60;
    },
    hasHourDiff() {
      const today = new Date();
      const date = new Date(this.datetime * 1000);

      const hours = differenceInHours(today, date);
      return hours >= 1 && hours <= 24;
    },
    hasDayDiff() {
      const today = new Date();
      const date = new Date(this.datetime * 1000);

      const days = differenceInDays(today, date);
      return days >= 1.5 && days <= 15;
    },
    hasMonthDiff() {
      const today = new Date();
      const date = new Date(this.datetime * 1000);
      const months = differenceInCalendarMonths(today, date);
      return months >= 1 && months <= 6;
    },
    hasYearDiff() {
      const today = new Date();
      const date = new Date(this.datetime * 1000);
      const years = differenceInCalendarYears(today, date);
      return years >= 1;
    },
    refreshTime() {
      if (this.refresh) {
        if (this.hasMinutesDiff && !this.hasHourDiff) {
          return 60000;
        }
        if (this.hasHourDiff && !this.hasDayDiff) {
          return 3600000;
        }
        // if (this.hasDayDiff && !this.hasMonthDiff) {
        //   return 86400000;
        // }
        // if (this.hasMonthDiff && !this.hasYearDiff) {
        //   return 2592000000;
        // }
        // if (this.hasYearDiff) {
        //   return 31536000000;
        // }
      }
      return false;
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
      this.timeago = this.dynamicTime(this.datetime);
      this.$nextTick(() => {
        if (this.refresh) {
          const refreshTime =
            this.refresh === true ? this.refreshTime : this.refresh;
          this.timer = setInterval(() => {
            this.timeago = this.dynamicTime(this.datetime);
          }, refreshTime);
        } else {
          this.timeago = this.dynamicTime(this.datetime);
        }
      });
    },
    clearTimer() {
      if (this.timer) clearInterval(this.timer);
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
