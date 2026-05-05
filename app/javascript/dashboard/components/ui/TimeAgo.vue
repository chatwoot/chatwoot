<script>
const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

import {
  dynamicTime,
  dateFormat,
  shortTimestamp,
  whatsappTimeFormat,
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
      lastActivityAtTimeAgo: dynamicTime(this.lastActivityTimestamp),
      createdAtTimeAgo: dynamicTime(this.createdAtTimestamp),
      timer: null,
    };
  },
  computed: {
    lastActivityTime() {
      if (!this.lastActivityTimestamp) {
        return shortTimestamp(this.lastActivityAtTimeAgo);
      }
      return whatsappTimeFormat(this.lastActivityTimestamp);
    },
    createdAtTime() {
      return shortTimestamp(this.createdAtTimeAgo);
    },
    createdAt() {
      const createdTimeDiff = Date.now() - this.createdAtTimestamp * 1000;
      const isBeforeAMonth = createdTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isBeforeAMonth
        ? `<span style="opacity: 0.8">${this.$t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.LATEST')}</span> <span style="color: #38bdf8; font-weight: 600;">${this.createdAtTimeAgo}</span>`
        : `<span style="opacity: 0.8">${this.$t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST')}</span> <span style="color: #38bdf8; font-weight: 600;">${dateFormat(this.createdAtTimestamp)}</span>`;
    },
    lastActivity() {
      const lastActivityTimeDiff =
        Date.now() - this.lastActivityTimestamp * 1000;
      const isNotActive = lastActivityTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isNotActive
        ? `<span style="opacity: 0.8">${this.$t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.ACTIVE')}</span> <span style="color: #34d399; font-weight: 600;">${this.lastActivityAtTimeAgo}</span>`
        : `<span style="opacity: 0.8">${this.$t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.NOT_ACTIVE')}</span> <span style="color: #34d399; font-weight: 600;">${dateFormat(this.lastActivityTimestamp)}</span>`;
    },
    tooltipText() {
      return `<div style="display: flex; flex-direction: column; gap: 6px; padding: 4px;">
                <div style="font-size: 13px;">${this.createdAt}</div>
                <div style="font-size: 13px;">${this.lastActivity}</div>
              </div>`;
    },
  },
  watch: {
    lastActivityTimestamp() {
      this.lastActivityAtTimeAgo = dynamicTime(this.lastActivityTimestamp);
    },
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
    createTimer() {
      this.timer = setTimeout(() => {
        this.lastActivityAtTimeAgo = dynamicTime(this.lastActivityTimestamp);
        this.createdAtTimeAgo = dynamicTime(this.createdAtTimestamp);
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

<template>
  <div
    v-tooltip.top="{
      content: tooltipText,
      delay: { show: 200, hide: 0 },
      hideOnClick: true,
      html: true,
    }"
    class="ml-auto leading-4 text-xxs"
    style="color: inherit;"
  >
    <span>{{ lastActivityTime }}</span>
  </div>
</template>
