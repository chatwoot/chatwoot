<template>
  <div class="notifications-page row">
    <div class="left-wrap medium-12">
      <notification-header />
      <notification-table
        :notifications="records"
        :is-loading="uiFlags.isFetching"
        :on-click-notification="openConversation"
      />
      <notification-footer
        :on-page-change="onPageChange"
        :current-page="1"
        :total-count="100"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import NotificationHeader from './Header';
import NotificationFooter from './Footer';
import NotificationTable from './NotificationTable';
export default {
  components: {
    NotificationHeader,
    NotificationTable,
    NotificationFooter,
  },
  computed: {
    ...mapGetters({
      records: 'notifications/getNotifications',
      uiFlags: 'notifications/getUIFlags',
      meta: 'notifications/getMeta',
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
      } = notification;

      this.$store.dispatch('notifications/read', {
        primaryActorId,
        primaryActorType,
        unReadCount: this.meta.unReadCount,
      });

      // const {
      //   primary_actor: { id: conversationId },
      // } = notification;
      // this.$router.push(
      //   `/app/accounts/${this.accountId}/conversations/${conversationId}`
      // );
    },
  },
};
</script>

<style lang="scss" scoped>
.notifications-page {
  width: 100%;
}
.left-wrap {
  display: flex;
  flex-direction: column;
  padding-top: var(--space-normal);
  height: 100%;
}
</style>
