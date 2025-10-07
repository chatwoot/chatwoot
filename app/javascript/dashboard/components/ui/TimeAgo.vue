<template>
  <div
    v-tooltip.top="{
      content: tooltipText,
      delay: { show: 1500, hide: 0 },
      hideOnClick: true,
    }"
    class="text-xxs text-slate-500 dark:text-slate-500 leading-4 ml-auto hover:text-slate-900 dark:hover:text-slate-100"
  >
    <span>{{ displayTime }}</span>
  </div>
</template>

<script>
const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

import timeMixin from 'dashboard/mixins/time';
import { mapGetters } from 'vuex';

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
    lastCustomerMessageTimestamp: {
      type: [String, Date, Number],
      default: null,
    },
  },
  data() {
    return {
      lastActivityAtTimeAgo: this.dynamicTime(this.lastActivityTimestamp),
      createdAtTimeAgo: this.dynamicTime(this.createdAtTimestamp),
      lastCustomerMessageAtTimeAgo: this.dynamicTime(
        this.lastCustomerMessageTimestamp || this.lastActivityTimestamp
      ),
      timer: null,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      getAccount: 'accounts/getAccount',
    }),
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
    showOnlyCustomerMessageTime() {
      // Check if account has the custom attribute set to show only customer message time
      return (
        this.currentAccount?.custom_attributes
          ?.show_only_customer_message_timestamp || false
      );
    },
    lastActivityTime() {
      // If enabled, show last customer message time instead of last_activity_at
      if (this.showOnlyCustomerMessageTime) {
        return this.shortTimestamp(this.lastCustomerMessageAtTimeAgo);
      }
      return this.shortTimestamp(this.lastActivityAtTimeAgo);
    },
    createdAtTime() {
      return this.shortTimestamp(this.createdAtTimeAgo);
    },
    lastCustomerMessageTime() {
      return this.shortTimestamp(this.lastCustomerMessageAtTimeAgo);
    },
    displayTime() {
      // Always show both created time and last activity time
      return `${this.createdAtTime} • ${this.lastActivityTime}`;
    },
    createdAt() {
      const createdTimeDiff = Date.now() - this.createdAtTimestamp * 1000;
      const isBeforeAMonth = createdTimeDiff > DAY_IN_MILLI_SECONDS * 30;
      return !isBeforeAMonth
        ? `${this.$t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.LATEST')} ${
            this.createdAtTimeAgo
          }`
        : `${this.$t(
            'CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST'
          )} ${this.dateFormat(this.createdAtTimestamp)}`;
    },
    lastActivity() {
      // Use customer message timestamp if enabled
      const timestampToUse = this.showOnlyCustomerMessageTime
        ? this.lastCustomerMessageTimestamp || this.lastActivityTimestamp
        : this.lastActivityTimestamp;
      const timeAgoToUse = this.showOnlyCustomerMessageTime
        ? this.lastCustomerMessageAtTimeAgo
        : this.lastActivityAtTimeAgo;

      const lastActivityTimeDiff = Date.now() - timestampToUse * 1000;
      const isNotActive = lastActivityTimeDiff > DAY_IN_MILLI_SECONDS * 30;

      // Update label based on whether we're showing user messages only
      const activeLabel = this.showOnlyCustomerMessageTime
        ? 'Last user message'
        : this.$t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.ACTIVE');
      const notActiveLabel = this.showOnlyCustomerMessageTime
        ? 'Last user message'
        : this.$t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.NOT_ACTIVE');

      return !isNotActive
        ? `${activeLabel} ${timeAgoToUse}`
        : `${notActiveLabel} ${this.dateFormat(timestampToUse)}`;
    },
    tooltipText() {
      return `${this.createdAt}
              ${this.lastActivity}`;
    },
  },
  watch: {
    lastActivityTimestamp() {
      this.lastActivityAtTimeAgo = this.dynamicTime(this.lastActivityTimestamp);
    },
    createdAtTimestamp() {
      this.createdAtTimeAgo = this.dynamicTime(this.createdAtTimestamp);
    },
    lastCustomerMessageTimestamp() {
      this.lastCustomerMessageAtTimeAgo = this.dynamicTime(
        this.lastCustomerMessageTimestamp || this.lastActivityTimestamp
      );
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
        this.lastCustomerMessageAtTimeAgo = this.dynamicTime(
          this.lastCustomerMessageTimestamp || this.lastActivityTimestamp
        );
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
