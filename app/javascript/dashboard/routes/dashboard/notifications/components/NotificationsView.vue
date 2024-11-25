<script>
import { mapGetters } from 'vuex';
import { useTrack } from 'dashboard/composables';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';

import NotificationTable from './NotificationTable.vue';

import { ACCOUNT_EVENTS } from '../../../../helper/AnalyticsHelper/events';
export default {
  components: {
    NotificationTable,
    TableFooter,
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      meta: 'notifications/getMeta',
      records: 'notifications/getNotifications',
      uiFlags: 'notifications/getUIFlags',
    }),
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

      useTrack(ACCOUNT_EVENTS.OPEN_CONVERSATION_VIA_NOTIFICATION, {
        notificationType,
      });
      this.$store.dispatch('notifications/read', {
        id: notification.id,
        primaryActorId,
        primaryActorType,
        unreadCount: this.meta.unreadCount,
      });

      this.$router.push(
        `/app/accounts/${this.accountId}/conversations/${conversationId}`
      );
    },
    onMarkAllDoneClick() {
      useTrack(ACCOUNT_EVENTS.MARK_AS_READ_NOTIFICATIONS);
      this.$store.dispatch('notifications/readAll');
    },
  },
};
</script>

<template>
  <div class="h-full overflow-y-auto">
    <div class="flex flex-col h-full">
      <NotificationTable
        :notifications="records"
        :is-loading="uiFlags.isFetching"
        :is-updating="uiFlags.isUpdating"
        :on-click-notification="openConversation"
        :on-mark-all-done-click="onMarkAllDoneClick"
      />
      <TableFooter
        class="border-t border-slate-75 dark:border-slate-700/50"
        :current-page="Number(meta.currentPage)"
        :total-count="meta.count"
        :page-size="15"
        @page-change="onPageChange"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.notification--page {
  background: var(--white);
  overflow-y: auto;
  width: 100%;
}

.notification--content {
  display: flex;
  flex-direction: column;
  height: 100%;
}
</style>
