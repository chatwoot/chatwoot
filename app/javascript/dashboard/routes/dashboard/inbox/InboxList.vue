<script>
import { mapGetters } from 'vuex';
import InboxCard from './components/InboxCard.vue';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
export default {
  components: {
    InboxCard,
    IntersectionObserver,
  },
  data() {
    return {
      infiniteLoaderOptions: {
        root: this.$refs.notificationList,
        rootMargin: '100px 0px 100px 0px',
      },
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
    this.$store.dispatch('notifications/get', { page: 1 });
  },
  methods: {
    onPageChange(page) {
      window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
      this.$store.dispatch('notifications/get', { page });
    },
    openConversation(notification) {
      const {
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
        primary_actor: { id: conversationId },
        notification_type: notificationType,
      } = notification;

      this.$track(ACCOUNT_EVENTS.OPEN_CONVERSATION_VIA_NOTIFICATION, {
        notificationType,
      });
      this.$store.dispatch('notifications/read', {
        primaryActorId,
        primaryActorType,
        unreadCount: this.meta.unreadCount,
      });
      this.$router.push(
        `/app/accounts/${this.accountId}/conversations/${conversationId}`
      );
    },
    onMarkAllDoneClick() {
      this.$track(ACCOUNT_EVENTS.MARK_AS_READ_NOTIFICATIONS);
      this.$store.dispatch('notifications/readAll');
    },
    endReached() {
      // if (this.meta.currentPage < this.meta.totalPages) {
      //   this.$store.dispatch('notifications/get', {
      //     page: this.meta.currentPage + 1,
      //   });
      // }
      return false;
    },
    loadMoreNotifications() {
      console.log('loadMoreConversations');
    },
  },
};
</script>
<template>
  <div
    class="inbox-list-view flex flex-col h-full ltr:border-r border-slate-50 dark:border-slate-800/50"
  >
    <div
      class="flex text-xl pl-5 pr-3 py-2 h-14 items-center font-medium text-slate-900 dark:text-slate-25 border-b border-slate-50 dark:border-slate-800/50"
    >
      Inbox
    </div>
    <div
      ref="notificationList"
      class="flex flex-col w-full h-full overflow-x-hidden overflow-y-auto"
    >
      <inbox-card
        v-for="notificationItem in records"
        :key="notificationItem.id"
        :notification-item="notificationItem"
      />
      <p v-if="showEndOfList" class="text-center text-muted p-4">
        {{ $t('INBOX.EOF') }}
      </p>
      <!-- <intersection-observer
        v-if="!showEndOfList && !uiFlags.isFetching"
        :options="infiniteLoaderOptions"
        @observed="loadMoreNotifications"
      /> -->
      <intersection-observer
        v-if="!uiFlags.isFetching"
        :options="infiniteLoaderOptions"
        @observed="loadMoreNotifications"
      />
    </div>
  </div>
</template>
<style scoped>
.inbox-list-view {
  width: clamp(360px, 22vw, 460px);
}
</style>
