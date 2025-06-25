<template>
  <div class="notifications-link">
    <woot-button
      class-names="notifications-link--button"
      variant="clear"
      color-scheme="secondary"
      :class="{ 'is-active': isNotificationPanelActive }"
      @click="openNotificationPanel"
    >
      <fluent-icon icon="alert" />
      <span v-if="unreadCount" class="badge warning">{{ unreadCount }}</span>
    </woot-button>
  </div>
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
        return '';
      }

      return this.notificationMetadata.unreadCount < 100
        ? `${this.notificationMetadata.unreadCount}`
        : '99+';
    },
    isNotificationPanelActive() {
      return this.$route.name === 'notifications_index';
    },
  },
  methods: {
    openNotificationPanel() {
      if (this.$route.name !== 'notifications_index') {
        this.$emit('open-notification-panel');
      }
    },
  },
};
</script>

<style scoped lang="scss">
.notifications-link {
  margin-bottom: var(--space-small);
}

.badge {
  position: absolute;
  right: var(--space-minus-smaller);
  top: var(--space-minus-smaller);
}
.notifications-link--button {
  display: flex;
  position: relative;
  border-radius: var(--border-radius-large);
  border: 1px solid transparent;
  color: var(--s-600);
  margin: var(--space-small) 0;

  &:hover {
    background: var(--w-50);
    color: var(--s-600);
  }

  &:focus {
    border-color: var(--w-500);
  }

  &.is-active {
    background: var(--w-50);
    color: var(--w-500);
  }
}
</style>
