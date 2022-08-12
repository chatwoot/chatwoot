<template>
  <span class="timeago">
    <span> {{ timeago }}</span>
  </span>
</template>

<script>
import timeMixin from 'dashboard/mixins/time';
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
      const diff = Math.abs(today - date);
      const minutes = Math.floor(diff / 1000 / 60);
      return minutes <= 60;
    },
    hasHourDiff() {
      const today = new Date();
      const date = new Date(this.datetime * 1000);

      const msInHour = 1000 * 60 * 60;

      const hours = Math.abs(date.getTime() - today.getTime()) / msInHour;
      return hours >= 1.5 && hours <= 24.0;
    },
    hasDayDiff() {
      const today = new Date();
      const date = new Date(this.datetime * 1000);

      const msInDay = 1000 * 60 * 60 * 24;

      const days = Math.abs(date.getTime() - today.getTime()) / msInDay;
      const daysRounded = Math.round(days);
      return daysRounded >= 1 && daysRounded <= 30;
    },
    // hasMonthDiff() {
    //   const today = new Date();
    //   const date = new Date(this.datetime * 1000);
    //   const months = today.getMonth() + 1 - (date.getMonth() + 1);
    //   return months >= 1 && months <= 12;
    // },
    // hasYearDiff() {
    //   const today = new Date();
    //   const date = new Date(this.datetime * 1000);
    //   const years = today.getFullYear() - date.getFullYear();
    //   return years >= 1;
    // },
    refreshTime() {
      if (this.refresh) {
        if (this.hasMinutesDiff && !this.hasHourDiff) {
          return 60000;
        }
        if (this.hasHourDiff && !this.hasDayDiff) {
          return 3600000;
        }
        // if (this.hasDayDiff && !this.hasMonthDiff) {
        //   return 60000000000000;
        // }
        // if (this.hasMonthDiff && !this.hasYearDiff) {
        //   return 60000000000000;
        // }
        // if (this.hasYearDiff) {
        //   return 60000000000000;
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
