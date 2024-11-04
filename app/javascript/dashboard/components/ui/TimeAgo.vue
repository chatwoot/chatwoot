<script>
const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

import useLocaleDateFormatter from 'dashboard/composables/useLocaleDateFormatter';

const { localeDynamicTime, localeDateFormat, localeShortTimestamp } =
  useLocaleDateFormatter();

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
      lastActivityAtTimeAgo: localeDynamicTime(this.lastActivityTimestamp),
      createdAtTimeAgo: localeDynamicTime(this.createdAtTimestamp),
      timer: null,
    };
  },
  computed: {
    lastActivityTime() {
      return localeShortTimestamp(this.lastActivityTimestamp, false);
    },
    createdAtTime() {
      return localeShortTimestamp(this.createdAtTimestamp, false);
    },
    createdAt() {
      const createdTimeDiff = Date.now() - this.createdAtTimestamp * 1000;
      const isBeforeAMonth = createdTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isBeforeAMonth
        ? `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.LATEST')} ${
            this.createdAtTimeAgo
          }`
        : `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST')} ${localeDateFormat(
            this.createdAtTimestamp
          )}`;
    },
    lastActivity() {
      const lastActivityTimeDiff =
        Date.now() - this.lastActivityTimestamp * 1000;
      const isNotActive = lastActivityTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isNotActive
        ? `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.ACTIVE')} ${this.lastActivityAtTimeAgo}`
        : `${this.$t(
            'CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.NOT_ACTIVE'
          )} ${localeDateFormat(this.lastActivityTimestamp)}`;
    },
    tooltipText() {
      return `${this.createdAt}
              ${this.lastActivity}`;
    },
  },
  watch: {
    lastActivityTimestamp() {
      this.lastActivityAtTimeAgo = localeDynamicTime(
        this.lastActivityTimestamp
      );
    },
    createdAtTimestamp() {
      this.createdAtTimeAgo = localeDynamicTime(this.createdAtTimestamp);
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
        this.lastActivityAtTimeAgo = localeDynamicTime(
          this.lastActivityTimestamp
        );
        this.createdAtTimeAgo = localeDynamicTime(this.createdAtTimestamp);
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
      delay: { show: 1500, hide: 0 },
      hideOnClick: true,
    }"
    class="ml-auto leading-4 text-xxs text-slate-500 dark:text-slate-500 hover:text-slate-900 dark:hover:text-slate-100"
  >
    <span>{{ `${createdAtTime} • ${lastActivityTime}` }}</span>
  </div>
</template>
