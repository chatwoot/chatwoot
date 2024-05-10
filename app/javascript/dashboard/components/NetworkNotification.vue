<template>
  <transition name="network-notification-fade" tag="div">
    <div v-show="showNotification" class="fixed top-4 left-2 z-50 group">
      <div
        class="flex items-center justify-between py-1 px-2 w-full rounded-lg shadow-lg bg-yellow-200 dark:bg-yellow-700 relative"
      >
        <fluent-icon
          icon="wifi-off"
          class="text-yellow-700/50 dark:text-yellow-50"
          size="18"
        />
        <span
          class="text-xs tracking-wide px-2 font-medium text-yellow-700/70 dark:text-yellow-50"
        >
          {{ bannerText }}
        </span>

        <woot-button
          v-if="!isReconnecting"
          :title="$t('NETWORK.BUTTON.REFRESH')"
          variant="clear"
          size="small"
          color-scheme="warning"
          icon="arrow-clockwise"
          class="visible transition-all duration-500 ease-in-out ml-1"
          @click="refreshPage"
        />
        <woot-button
          variant="clear"
          size="small"
          color-scheme="warning"
          icon="dismiss"
          @click="closeNotification"
        />
      </div>
    </div>
  </transition>
</template>

<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  mixins: [globalConfigMixin],

  data() {
    return {
      showNotification: !navigator.onLine,
      isReconnecting: false,
    };
  },

  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    bannerText() {
      return this.isReconnecting
        ? this.$t('NETWORK.NOTIFICATION.RECONNECT')
        : this.$t('NETWORK.NOTIFICATION.OFFLINE');
    },
  },

  mounted() {
    window.addEventListener('offline', this.updateOnlineStatus);
    window.addEventListener('online', this.updateOnlineStatus);
    window.bus.$on(BUS_EVENTS.WEBSOCKET_DISCONNECT, () => {
      this.updateOnlineStatus({ type: 'offline' });
    });
    window.bus.$on(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED, () => {
      this.showNotification = false;
      this.isReconnecting = false;
    });
    window.bus.$on(BUS_EVENTS.WEBSOCKET_RECONNECT, () => {
      this.isReconnecting = true;
    });
  },

  beforeDestroy() {
    window.removeEventListener('offline', this.updateOnlineStatus);
    window.removeEventListener('online', this.updateOnlineStatus);
    window.bus.$off(BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED);
    window.bus.$off(BUS_EVENTS.WEBSOCKET_RECONNECT);
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
