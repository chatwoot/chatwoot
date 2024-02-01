<script>
import { mapGetters } from 'vuex';
import InboxCard from './components/InboxCard.vue';
import InboxListHeader from './components/InboxListHeader.vue';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
export default {
  components: {
    InboxCard,
    InboxListHeader,
    IntersectionObserver,
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
    loadMoreNotifications() {
      if (this.uiFlags.isAllNotificationsLoaded) return;
      this.$store.dispatch('notifications/index', { page: this.page + 1 });
      this.page += 1;
    },
  },
};
</script>
<template>
  <div
    class="flex flex-col min-w-[360px] w-full max-w-[360px] h-full ltr:border-r border-slate-50 dark:border-slate-800/50"
  >
    <inbox-list-header />
    <div
      ref="notificationList"
      class="flex flex-col w-full h-full overflow-x-hidden overflow-y-auto"
    >
      <inbox-card
        v-for="notificationItem in records"
        :key="notificationItem.id"
        :notification-item="notificationItem"
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
