<template>
  <div class="notifications-link">
    <primary-nav-item
      name="NOTIFICATIONS"
      icon="alert"
      :to="`/app/accounts/${accountId}/notifications`"
      :count="unreadCount"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import PrimaryNavItem from './PrimaryNavItem';

export default {
  components: { PrimaryNavItem },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      notificationMetadata: 'notifications/getMeta',
    }),
    unreadCount() {
      if (!this.notificationMetadata.unreadCount) {
        return '';
      }

      return this.notificationMetadata.unreadCount < 100
        ? `${this.notificationMetadata.unreadCount}`
        : '99+';
    },
  },
  methods: {},
};
</script>

<style scoped lang="scss">
.notifications-link {
  margin-bottom: var(--space-small);
}
</style>
