<template>
  <transition name="network-notification-fade" tag="div">
    <div v-show="showNotification" class="ui-notification-container">
      <div class="ui-notification">
        <fluent-icon icon="wifi-off" />
        <p class="ui-notification-text">
          {{ $t('NETWORK.NOTIFICATION.TEXT') }}
        </p>
        <woot-button variant="clear" size="small" @click="refreshPage">
          {{ $t('NETWORK.BUTTON.REFRESH') }}
        </woot-button>
        <woot-button
          variant="clear"
          size="small"
          color-scheme="secondary"
          icon="dismiss-circle"
          @click="closeNotification"
        >
        </woot-button>
      </div>
    </div>
  </transition>
</template>

<script>
export default {
  data() {
    return {
      showNotification: !navigator.onLine,
    };
  },

  mounted() {
    window.addEventListener('offline', this.updateOnlineStatus);
  },

  beforeDestroy() {
    window.removeEventListener('offline', this.updateOnlineStatus);
  },

  methods: {
    refreshPage() {
      window.location.reload();
    },

    closeNotification() {
      this.showNotification = false;
    },

    updateOnlineStatus(event) {
      if (event.type === 'offline') {
        this.showNotification = true;
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/mixins';

.ui-notification-container {
  max-width: 40rem;
  position: absolute;
  right: var(--space-normal);
  top: var(--space-normal);
  z-index: var(--z-index-very-high);
}

.ui-notification {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;

  background-color: var(--y-100);
  border-radius: var(--border-radius-medium);
  box-shadow: var(--shadow-large);

  min-width: 24rem;
  padding: var(--space-normal);
}

.ui-notification-text {
  margin: 0 var(--space-small);
}
</style>
