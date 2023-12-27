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
          class="text-xs tracking-wide font-medium px-2 text-yellow-700/70 dark:text-yellow-50"
        >
          {{ $t('NETWORK.NOTIFICATION.OFFLINE') }}
        </span>
        <woot-button
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
    };
  },

  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },

  mounted() {
    window.addEventListener('offline', this.updateOnlineStatus);
    window.bus.$on(BUS_EVENTS.WEBSOCKET_DISCONNECT, () => {
      // TODO: Remove this after completing the conversation list refetching
      // TODO: DIRTY FIX : CLEAN UP THIS WITH PROPER FIX, DELAYING THE RECONNECT FOR NOW
      // THE CABLE IS FIRING IS VERY COMMON AND THUS INTERFERING USER EXPERIENCE
      setTimeout(() => {
        this.updateOnlineStatus({ type: 'offline' });
      }, 4000);
    });
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
