<template>
  <transition name="network-notification-fade" tag="div">
    <div v-show="showNotification" class="ui-notification-container">
      <div class="ui-notification">
        <svg
          class="ui-notification-icon"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3m8.293 8.293l1.414 1.414"
          />
        </svg>
        <p class="ui-notification-text">
          {{ $t('NETWORK.NOTIFICATION.TEXT') }}
        </p>
        <button class="ui-refresh-button" @click="refreshPage">
          {{ $t('NETWORK.BUTTON.REFRESH') }}
        </button>
        <button class="ui-close-button" @click="closeNotification">
          <i class="ui-close-icon icon ion-ios-close-outline" />
        </button>
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
  width: 100%;
  z-index: 9999;
}

.ui-notification {
  @include shadow;
  align-items: center;
  background-color: var(--white);
  border: 1px solid var(--color-border);
  border-radius: var(--space-one);
  display: flex;
  justify-content: space-between;
  max-width: 40rem;
  min-height: 3rem;
  min-width: 24rem;
  padding: var(--space-normal) var(--space-two);
  text-align: left;
}

.ui-notification-text {
  margin: 0;
}

.ui-refresh-button {
  color: var(--color-woot);
  font-size: var(--font-size-small);
  font-weight: bold;

  &:hover {
    cursor: pointer;
  }
}

.ui-notification-icon {
  color: var(--b-600);
  width: var(--font-size-mega);
}

.ui-close-icon {
  color: var(--b-600);
  font-size: var(--font-size-large);
}

.ui-close-button {
  &:hover {
    cursor: pointer;
  }
}
</style>
