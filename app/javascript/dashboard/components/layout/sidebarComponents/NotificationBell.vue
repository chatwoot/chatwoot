<template>
  <span class="notifications icon ion-ios-bell" @click.stop="showNotification">
    <span v-if="unreadCount" class="unread-badge">{{ unreadCount }}</span>
  </span>
</template>
<script>
import { mapGetters } from 'vuex';
export default {
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      notificationMetadata: 'notifications/getMeta',
    }),
    unreadCount() {
      if (!this.notificationMetadata.unreadCount) {
        return 0;
      }

      return this.notificationMetadata.unreadCount < 100
        ? this.notificationMetadata.unreadCount
        : '99+';
    },
  },
  methods: {
    showNotification() {
      this.$router.push(`/app/accounts/${this.accountId}/notifications`);
    },
  },
};
</script>

<style scoped lang="scss">
.notifications {
  font-size: var(--font-size-big);
  margin-bottom: auto;
  margin-left: auto;
  margin-top: auto;
  position: relative;

  .unread-badge {
    background: var(--r-300);
    border-radius: var(--space-small);
    color: var(--white);
    font-size: var(--font-size-micro);
    font-weight: var(--font-weight-black);
    left: var(--space-slab);
    padding: 0 var(--space-smaller);
    position: absolute;
    top: var(--space-smaller);
  }
}
</style>
