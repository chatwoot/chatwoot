<template>
  <div class="notifications-link">
    <button
      class="notifications-link--button button clear"
      :class="{ 'is-active': isNotificationPanelActive }"
      @click="openNotificationPanel"
    >
      <fluent-icon icon="alert" />
      <span v-if="unreadCount" class="badge warning">{{ unreadCount }}</span>
    </button>
    <notification-panel
      v-if="isNotificationPanel"
      @close="closeNotificationPanel"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import NotificationPanel from 'dashboard/routes/dashboard/notifications/components/NotificationPanel.vue';

export default {
  components: {
    NotificationPanel,
  },
  data() {
    return {
      isNotificationPanel: false,
    };
  },
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
      return (
        this.isNotificationPanel === true ||
        this.$route.name === 'notifications_index'
      );
    },
  },
  methods: {
    openNotificationPanel() {
      if (this.$route.name !== 'notifications_index') {
        this.isNotificationPanel = true;
      }
    },
    closeNotificationPanel() {
      this.isNotificationPanel = false;
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
