<template>
  <transition name="network-notification-fade" tag="div">
    <div v-show="showNotification" class="ui-notification-container">
      <div class="ui-notification">
        <fluent-icon icon="wifi-off" />
        <p class="ui-notification-text">
          {{
            useInstallationName(
              $t('NETWORK.NOTIFICATION.TEXT'),
              globalConfig.installationName
            )
          }}
        </p>
        <woot-button variant="clear" size="small" @click="refreshPage">
          {{ $t('NETWORK.BUTTON.REFRESH') }}
        </woot-button>
        <woot-button
          variant="smooth"
          size="small"
          color-scheme="warning"
          icon="dismiss-circle"
          @click="closeNotification"
        />
      </div>
    </div>
  </transition>
</template>

<script>
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';

export default {
  mixins: [globalConfigMixin],

  data() {
    return {
      // showNotification: !navigator.onLine,
      showNotification: false,
    };
  },

  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },

  mounted() {
    // TODO: Commented out for now as it is causing issues with the testing of action cable reconnect
    // window.addEventListener('offline', this.updateOnlineStatus);
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
