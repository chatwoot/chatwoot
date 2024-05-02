<template>
  <div
    class="flex gap-2 py-2 ltr:pl-4 rtl:pl-2 h-14 ltr:pr-2 rtl:pr-4 rtl:border-r justify-between items-center w-full border-b border-slate-50 dark:border-slate-800/50"
  >
    <woot-button
      variant="clear link"
      class="flex md:hidden !pt-1 !pb-1 rounded-md ltr:pr-1 rtl:pl-1 !no-underline"
      size="medium"
      color-scheme="primary"
      icon="chevron-left"
      @click="onClickGoToInboxList"
    >
      {{ $t('INBOX.ACTION_HEADER.BACK') }}
    </woot-button>
    <pagination-button
      v-if="totalLength > 1"
      :total-length="totalLength"
      :current-index="currentIndex + 1"
      @next="onClickNext"
      @prev="onClickPrev"
    />
    <div v-else />
    <div class="flex items-center gap-2">
      <woot-button
        variant="hollow"
        size="small"
        color-scheme="secondary"
        icon="snooze"
        class="[&>span]:hidden md:[&>span]:inline-flex"
        @click="openSnoozeNotificationModal"
      >
        {{ $t('INBOX.ACTION_HEADER.SNOOZE') }}
      </woot-button>
      <woot-button
        icon="delete"
        size="small"
        color-scheme="secondary"
        variant="hollow"
        class="[&>span]:hidden md:[&>span]:inline-flex"
        @click="deleteNotification"
      >
        {{ $t('INBOX.ACTION_HEADER.DELETE') }}
      </woot-button>
    </div>
    <woot-modal
      :show.sync="showCustomSnoozeModal"
      :on-close="hideCustomSnoozeModal"
    >
      <custom-snooze-modal
        @close="hideCustomSnoozeModal"
        @choose-time="scheduleCustomSnooze"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { getUnixTime } from 'date-fns';
import { CMD_SNOOZE_NOTIFICATION } from 'dashboard/routes/dashboard/commands/commandBarBusEvents';
import wootConstants from 'dashboard/constants/globals';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import PaginationButton from './PaginationButton.vue';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal.vue';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    PaginationButton,
    CustomSnoozeModal,
  },
  mixins: [alertMixin],
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
    return { showCustomSnoozeModal: false };
  },
  computed: {
    ...mapGetters({ meta: 'notifications/getMeta' }),
  },
  mounted() {
    bus.$on(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  destroyed() {
    bus.$off(CMD_SNOOZE_NOTIFICATION, this.onCmdSnoozeNotification);
  },
  methods: {
    openSnoozeNotificationModal() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'snooze_notification' });
    },
    hideCustomSnoozeModal() {
      this.showCustomSnoozeModal = false;
    },
    async snoozeNotification(snoozedUntil) {
      try {
        await this.$store.dispatch('notifications/snooze', {
          id: this.activeNotification?.id,
          snoozedUntil,
        });

        this.showAlert(this.$t('INBOX.ALERTS.SNOOZE'));
      } catch (error) {
        // Silently fail without any change in the UI
      }
    },
    onCmdSnoozeNotification(snoozeType) {
      if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.showCustomSnoozeModal = true;
      } else {
        const snoozedUntil = findSnoozeTime(snoozeType) || null;
        this.snoozeNotification(snoozedUntil);
      }
    },
    scheduleCustomSnooze(customSnoozeTime) {
      this.showCustomSnoozeModal = false;
      if (customSnoozeTime) {
        const snoozedUntil = getUnixTime(customSnoozeTime) || null;
        this.snoozeNotification(snoozedUntil);
      }
    },
    deleteNotification() {
      this.$track(INBOX_EVENTS.DELETE_NOTIFICATION);
      this.$store
        .dispatch('notifications/delete', {
          notification: this.activeNotification,
          unread_count: this.meta.unreadCount,
          count: this.meta.count,
        })
        .then(() => {
          this.showAlert(this.$t('INBOX.ALERTS.DELETE'));
        });
      this.$router.replace({ name: 'inbox_view' });
    },
    onClickNext() {
      this.$emit('next');
    },
    onClickPrev() {
      this.$emit('prev');
    },
    onClickGoToInboxList() {
      this.$router.replace({ name: 'inbox_view' });
    },
  },
};
</script>
