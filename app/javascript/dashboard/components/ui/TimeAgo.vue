<script>
const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

import {
  dynamicTime,
  dateFormat,
  shortTimestamp,
} from 'shared/helpers/timeHelper';

export default {
  name: 'TimeAgo',
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
      createdAtTimeAgo: dynamicTime(this.createdAtTimestamp),
      now: Date.now(),
      timer: null,
    };
  },
  computed: {
    lastActivityTime() {
      return this.formatMmSs(this.lastActivityTimestamp);
    },
    createdAtTime() {
      return shortTimestamp(this.createdAtTimeAgo);
    },
    createdAt() {
      const createdTimeDiff = Date.now() - this.createdAtTimestamp * 1000;
      const isBeforeAMonth = createdTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isBeforeAMonth
        ? `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.LATEST')} ${
            this.createdAtTimeAgo
          }`
        : `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST')} ${dateFormat(
            this.createdAtTimestamp
          )}`;
    },
    lastActivity() {
      const lastActivityTimeDiff = this.now - this.lastActivityTimestamp * 1000;
      const isNotActive = lastActivityTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isNotActive
        ? `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.ACTIVE')} ${this.formatMmSs(this.lastActivityTimestamp)}`
        : `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.NOT_ACTIVE')} ${dateFormat(this.lastActivityTimestamp)}`;
    },
    tooltipText() {
      return `${this.createdAt}
              ${this.lastActivity}`;
    },
  },
  watch: {
    createdAtTimestamp() {
      this.createdAtTimeAgo = dynamicTime(this.createdAtTimestamp);
    },
  },
  mounted() {
    if (this.isAutoRefreshEnabled) {
      this.createTimer();
    }
  },
  unmounted() {
    clearTimeout(this.timer);
  },
  methods: {
    formatMmSs(timestamp) {
      if (!timestamp) return '--:--';
      const diffSeconds = Math.floor(this.now / 1000 - timestamp);
      if (diffSeconds < 0) return '0s';

      if (diffSeconds < 60) {
        return `${diffSeconds}s`;
      }

      if (diffSeconds < 3600) {
        const m = Math.floor(diffSeconds / 60);
        const s = diffSeconds % 60;
        return `${m}m ${s}s`;
      }

      if (diffSeconds < 86400) {
        const h = Math.floor(diffSeconds / 3600);
        const m = Math.floor((diffSeconds % 3600) / 60);
        const s = diffSeconds % 60;
        return `${h}h ${m}m ${s}s`;
      }

      if (diffSeconds < 86400 * 30) {
        const d = Math.floor(diffSeconds / 86400);
        const h = Math.floor((diffSeconds % 86400) / 3600);
        const m = Math.floor((diffSeconds % 3600) / 60);
        return `${d}d ${h}h ${m}m`;
      }

      return dynamicTime(timestamp);
    },
    createTimer() {
      this.timer = setTimeout(() => {
        this.now = Date.now();
        this.createdAtTimeAgo = dynamicTime(this.createdAtTimestamp);
        this.createTimer();
      }, this.refreshTime());
    },
    refreshTime() {
      return 1000;
    },
  },
};
</script>

<template>
  <div
    v-tooltip.top="{
      content: tooltipText,
      delay: { show: 1000, hide: 0 },
      hideOnClick: true,
    }"
    class="ml-auto leading-4 text-xs text-n-slate-10 hover:text-n-slate-11"
  >
    <span>{{ `${createdAtTime} • ${lastActivityTime}` }}</span>
  </div>
</template>
