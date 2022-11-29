<template>
  <span class="time-ago">
    <span>{{ timeAgo }}</span>
  </span>
</template>

<script>
const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

import timeMixin from 'dashboard/mixins/time';

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
      timeAgo: this.dynamicTime(this.timestamp),
      timer: null,
    };
  },
  watch: {
    timestamp() {
      this.timeAgo = this.dynamicTime(this.timestamp);
    },
  },
  mounted() {
    if (this.isAutoRefreshEnabled) {
      this.createTimer();
    }
  },
  beforeDestroy() {
    clearTimeout(this.timer);
  },
  methods: {
    createTimer() {
      this.timer = setTimeout(() => {
        this.timeAgo = this.dynamicTime(this.timestamp);
        this.createTimer();
      }, this.refreshTime());
    },
    refreshTime() {
      const timeDiff = Date.now() - this.timestamp * 1000;
      if (timeDiff > DAY_IN_MILLI_SECONDS) {
        return DAY_IN_MILLI_SECONDS;
      }
      if (timeDiff > HOUR_IN_MILLI_SECONDS) {
        return HOUR_IN_MILLI_SECONDS;
      }

      return MINUTE_IN_MILLI_SECONDS;
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
