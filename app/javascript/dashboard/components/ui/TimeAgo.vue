<template>
  <span class="time-ago">
    <span> {{ timeAgo }}</span>
  </span>
</template>

<script>
const ZERO = 0;
const MINUTE_IN_MILLI_SECOND = 60000;
const HOUR_IN_MILLI_SECOND = MINUTE_IN_MILLI_SECOND * 60;
const DAY_IN_MILLI_SECOND = HOUR_IN_MILLI_SECOND * 24;
const MONTH_IN_MILLI_SECOND = DAY_IN_MILLI_SECOND * 30;
const YEAR_IN_MILLI_SECOND = MONTH_IN_MILLI_SECOND * 12;

import timeMixin from 'dashboard/mixins/time';
import { differenceInMilliseconds } from 'date-fns';

export default {
  name: 'TimeAgo',
  mixins: [timeMixin],
  props: {
    isAutoRefreshEnabled: {
      type: Boolean,
      default: true,
    },
    timestamp: {
      type: [String, Date, Number],
      default: '',
    },
  },
  data() {
    return {
      timeAgo: '',
      timer: null,
    };
  },
  computed: {
    refreshTime() {
      const timeDiff = differenceInMilliseconds(
        new Date(),
        new Date(this.timestamp * 1000)
      );
      if (
        timeDiff > MINUTE_IN_MILLI_SECOND &&
        timeDiff < HOUR_IN_MILLI_SECOND
      ) {
        return MINUTE_IN_MILLI_SECOND;
      }
      if (timeDiff > HOUR_IN_MILLI_SECOND && timeDiff < DAY_IN_MILLI_SECOND) {
        return HOUR_IN_MILLI_SECOND;
      }
      if (timeDiff > DAY_IN_MILLI_SECOND && timeDiff < MONTH_IN_MILLI_SECOND) {
        return DAY_IN_MILLI_SECOND;
      }
      if (timeDiff > MONTH_IN_MILLI_SECOND && timeDiff < YEAR_IN_MILLI_SECOND) {
        return MONTH_IN_MILLI_SECOND;
      }
      if (timeDiff > YEAR_IN_MILLI_SECOND) {
        return YEAR_IN_MILLI_SECOND;
      }
      return ZERO;
    },
  },
  mounted() {
    this.timeAgo = this.dynamicTime(this.timestamp);
    if (this.isRefreshEnabled) {
      this.createTimer();
    }
  },
  beforeDestroy() {
    this.clearTimer();
  },
  methods: {
    createTimer() {
      this.$nextTick(() => {
        const refreshTime = this.refreshTime;
        if (refreshTime > ZERO) {
          this.timer = setTimeout(() => {
            this.timeAgo = this.dynamicTime(this.timestamp);
            this.createTimer();
          }, refreshTime);
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
.time-ago {
  color: var(--b-600);
  font-size: var(--font-size-micro);
  font-weight: var(--font-weight-normal);
  line-height: var(--space-normal);
  margin-left: auto;
}
</style>
