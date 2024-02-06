<template>
  <div
    class="flex flex-col h-full w-full ltr:border-r border-slate-50 dark:border-slate-800/50"
    :class="isOnExpandedLayout ? '' : 'min-w-[360px] max-w-[360px]'"
  >
    <inbox-list-header />
    <div
      ref="notificationList"
      class="flex flex-col w-full h-[calc(100%-56px)] overflow-x-hidden overflow-y-auto"
    >
      <inbox-card
        v-for="notificationItem in records"
        :key="notificationItem.id"
        :notification-item="notificationItem"
        @mark-notification-as-read="markNotificationAsRead"
        @mark-notification-as-unread="markNotificationAsUnRead"
        @delete-notification="deleteNotification"
      />
      <div v-if="uiFlags.isFetching" class="text-center">
        <span class="spinner mt-4 mb-4" />
      </div>
      <p
        v-if="showEndOfList"
        class="text-center text-slate-300 dark:text-slate-400 p-4"
      >
        {{ $t('INBOX.LIST.EOF') }}
      </p>
      <intersection-observer
        v-if="!showEndOfList && !uiFlags.isFetching"
        :options="infiniteLoaderOptions"
        @observed="loadMoreNotifications"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import InboxCard from './components/InboxCard.vue';
import InboxListHeader from './components/InboxListHeader.vue';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    InboxCard,
    InboxListHeader,
    IntersectionObserver,
  },
  mixins: [alertMixin],
  props: {
    conversationId: {
      type: [String, Number],
      default: 0,
    },
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      infiniteLoaderOptions: {
        root: this.$refs.notificationList,
        rootMargin: '100px 0px 100px 0px',
      },
      page: 1,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      meta: 'notifications/getMeta',
      records: 'notifications/getNotifications',
      uiFlags: 'notifications/getUIFlags',
    }),
    showEndOfList() {
      return this.uiFlags.isAllNotificationsLoaded && !this.uiFlags.isFetching;
    },
  },
  mounted() {
    this.$store.dispatch('notifications/clear');
    this.$store.dispatch('notifications/index', { page: 1 });
  },
  methods: {
    redirectToInbox() {
      if (!this.conversationId) return;
      if (this.$route.name === 'inbox') return;
      this.$router.push({ name: 'inbox' });
    },
    loadMoreNotifications() {
      if (this.uiFlags.isAllNotificationsLoaded) return;
      this.$store.dispatch('notifications/index', { page: this.page + 1 });
      this.page += 1;
    },
    markNotificationAsRead(notification) {
      this.$track(INBOX_EVENTS.MARK_NOTIFICATION_AS_READ);
      const {
        id,
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
      } = notification;
      this.$store
        .dispatch('notifications/read', {
          id,
          primaryActorId,
          primaryActorType,
          unreadCount: this.meta.unreadCount,
        })
        .then(() => {
          this.showAlert(this.$t('INBOX.ALERTS.MARK_AS_READ'));
        });
    },
    markNotificationAsUnRead(notification) {
      this.$track(INBOX_EVENTS.MARK_NOTIFICATION_AS_UNREAD);
      this.redirectToInbox();
      const { id } = notification;
      this.$store
        .dispatch('notifications/unread', {
          id,
        })
        .then(() => {
          this.showAlert(this.$t('INBOX.ALERTS.MARK_AS_UNREAD'));
        });
    },
    deleteNotification(notification) {
      this.$track(INBOX_EVENTS.DELETE_NOTIFICATION);
      this.redirectToInbox();
      this.$store
        .dispatch('notifications/delete', {
          notification,
          unread_count: this.meta.unreadCount,
          count: this.meta.count,
        })
        .then(() => {
          this.showAlert(this.$t('INBOX.ALERTS.DELETE'));
        });
    },
  },
};
</script>
