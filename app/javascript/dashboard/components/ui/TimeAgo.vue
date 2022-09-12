<template>
  <span class="time-ago">
    <span> {{ timeAgo }}</span>
  </span>
</template>

<script>
const ZERO = 0;
const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

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
      if (timeDiff > DAY_IN_MILLI_SECONDS) {
        return DAY_IN_MILLI_SECONDS;
      }
      if (timeDiff > HOUR_IN_MILLI_SECONDS) {
        return HOUR_IN_MILLI_SECONDS;
      }
      if (timeDiff > MINUTE_IN_MILLI_SECONDS) {
        return MINUTE_IN_MILLI_SECONDS;
      }
      return ZERO;
    },
  },
  mounted() {
    this.timeAgo = this.dynamicTime(this.timestamp);
    if (this.isAutoRefreshEnabled) {
      this.createTimer();
    }
  },
  beforeDestroy() {
    this.clearTimer();
  },
  methods: {
    createTimer() {
      const refreshTime = this.refreshTime;
      if (refreshTime > ZERO) {
        this.timer = setTimeout(() => {
          this.timeAgo = this.dynamicTime(this.timestamp);
          this.createTimer();
        }, refreshTime);
      }
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
