<template>
  <div class="columns notification--page">
    <div class="notification--content medium-12">
      <notification-table
        :notifications="records"
        :is-loading="uiFlags.isFetching"
        :is-updating="uiFlags.isUpdating"
        :on-click-notification="openConversation"
        :on-mark-all-done-click="onMarkAllDoneClick"
      />
      <table-footer
        :current-page="Number(meta.currentPage)"
        :total-count="meta.count"
        @page-change="onPageChange"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import TableFooter from 'dashboard/components/widgets/TableFooter';

import NotificationTable from './NotificationTable';
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
      } = notification;

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
      this.$store.dispatch('notifications/readAll');
    },
  },
};
</script>

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
