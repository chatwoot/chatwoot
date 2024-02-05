<template>
  <div
    class="flex gap-2 py-2 pl-4 h-14 pr-2 justify-between items-center w-full border-b border-slate-50 dark:border-slate-800/50"
  >
    <pagination-button
      :total-length="totalLength"
      :current-index="currentIndex"
      @next="onClickNext"
      @prev="onClickPrev"
    />
    <div class="flex items-center gap-2">
      <woot-button
        variant="hollow"
        size="small"
        color-scheme="secondary"
        icon="snooze"
        @click="openSnoozeNotificationModal"
      >
        {{ $t('INBOX.ACTION_HEADER.SNOOZE') }}
      </woot-button>
      <woot-button
        icon="delete"
        size="small"
        color-scheme="secondary"
        variant="hollow"
        @click="deleteNotification"
      >
        {{ $t('INBOX.ACTION_HEADER.DELETE') }}
      </woot-button>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import PaginationButton from './PaginationButton.vue';
import { CMD_SNOOZE_NOTIFICATION } from 'dashboard/routes/dashboard/commands/commandBarBusEvents';
import wootConstants from 'dashboard/constants/globals';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

export default {
  components: {
    PaginationButton,
  },
  props: {
    totalLength: {
      type: Number,
      default: 0,
    },
    currentIndex: {
      type: Number,
      default: 0,
    },
    activeNotification: {
      type: Object,
      default: null,
    },
  },
  data() {
    return {
      showCustomSnoozeModal: false,
    };
  },
  computed: {
    ...mapGetters({
      meta: 'notifications/getMeta',
    }),
  },
  mounted() {
    bus.$on(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  destroyed() {
    bus.$off(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  methods: {
    onCmdSnoozeNotification(snoozeType) {
      if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.showCustomSnoozeModal = true;
      } else {
        this.$store.dispatch('notifications/snooze', {
          id: this.activeNotification?.id,
          snoozedUntil: findSnoozeTime(snoozeType) || null,
        });
      }
    },
    openSnoozeNotificationModal() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'snooze_notification' });
    },
    deleteNotification() {
      this.$track(INBOX_EVENTS.DELETE_NOTIFICATION);
      this.$store.dispatch('notifications/delete', {
        notification: this.activeNotification,
        unread_count: this.meta.unreadCount,
        count: this.meta.count,
      });
      this.$router.push({ name: 'inbox' });
    },
    onDelete() {},
    onClickNext() {
      this.$emit('next');
    },
    onClickPrev() {
      this.$emit('prev');
    },
  },
};
</script>
