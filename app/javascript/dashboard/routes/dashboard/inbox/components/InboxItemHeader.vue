<template>
  <div
    class="flex gap-2 py-2 ltr:pl-4 rtl:pl-2 h-14 ltr:pr-2 rtl:pr-4 rtl:border-r justify-between items-center w-full border-b border-slate-50 dark:border-slate-800/50"
  >
    <pagination-button
      v-if="totalLength > 1"
      :total-length="totalLength"
      :current-index="currentIndex"
      @next="onClickNext"
      @prev="onClickPrev"
    />
    <div v-else />
    <div class="flex items-center gap-2">
      <woot-button
        v-if="!isNotificationAlreadySnoozed"
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
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import PaginationButton from './PaginationButton.vue';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    PaginationButton,
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
    return {
      showCustomSnoozeModal: false,
    };
  },
  computed: {
    ...mapGetters({
      meta: 'notifications/getMeta',
    }),
    isNotificationAlreadySnoozed() {
      return this.activeNotification?.snoozed_until;
    },
  },
  methods: {
    openSnoozeNotificationModal() {
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'snooze_notification' });
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
      this.$router.push({ name: 'inbox_view' });
    },
    onClickNext() {
      this.$emit('next');
    },
    onClickPrev() {
      this.$emit('prev');
    },
  },
};
</script>
