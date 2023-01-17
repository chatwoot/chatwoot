<template>
  <div
    v-tooltip.top="{
      content: tooltipText,
      delay: { show: 300, hide: 0 },
      hideOnClick: true,
    }"
    class="time-ago"
  >
    <span>{{ createdAtTime }}</span>
    <fluent-icon icon="circle" size="4" class="icon" />
    <span>{{ lastActivityTime }}</span>
  </div>
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
    lastActivityTimestamp: {
      type: [String, Date, Number],
      default: '',
    },
    createdAtTimestamp: {
      type: [String, Date, Number],
      default: '',
    },
  },
  data() {
    return {
      lastActivityAtTimeAgo: this.dynamicTime(this.lastActivityTimestamp),
      createdAtTimeAgo: this.dynamicTime(this.createdAtTimestamp),
      timer: null,
    };
  },
  computed: {
    lastActivityTime() {
      return this.shortTimestamp(this.lastActivityAtTimeAgo);
    },
    createdAtTime() {
      return this.shortTimestamp(this.createdAtTimeAgo);
    },
    tooltipText() {
      return `Created at: ${this.createdAtTimeAgo}
              Last activity: ${this.lastActivityAtTimeAgo}`;
    },
  },
  watch: {
    lastActivityTimestamp() {
      this.lastActivityAtTimeAgo = this.dynamicTime(this.lastActivityTimestamp);
    },
    createdAtTimestamp() {
      this.createdAtTimeAgo = this.dynamicTime(this.createdAtTimestamp);
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
        this.lastActivityAtTimeAgo = this.dynamicTime(
          this.lastActivityTimestamp
        );
        this.createdAtTimeAgo = this.dynamicTime(this.createdAtTimestamp);
        this.createTimer();
      }, this.refreshTime());
    },
    refreshTime() {
      const timeDiff = Date.now() - this.lastActivityTimestamp * 1000;
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

  &:hover {
    color: var(--b-900);
  }

  .icon {
    vertical-align: middle;
  }
}
</style>
