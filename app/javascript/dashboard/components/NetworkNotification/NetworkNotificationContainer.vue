<template>
  <!-- TODO: Change to transition group -->
  <div v-show="show" class="ui-notification-container">
    <div class="ui-notification">
      <i class="ui-notification-icon icon ion-radio-waves" />
      <p class="ui-notification-text">
        Disconnected from chatwoot
      </p>
      <button class="ui-refresh-button" @click="refreshPage()">
        Refresh
      </button>
      <button @click="print('Closed!')">
        <i class="ui-close-icon icon ion-ios-close-outline" />
      </button>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },

  methods: {
    refreshPage() {
      window.location.reload();
    },
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';

.ui-notification-container {
  width: 100%;
  max-width: 40rem;
  overflow: hidden;
  position: absolute;
  right: 0;
  top: $space-normal;
  z-index: 9999;
}

.ui-notification {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background-color: $color-white;
  border-radius: $space-one;
  margin-right: $space-normal;
  max-width: 40rem;
  min-height: 3rem;
  min-width: 24rem;
  text-align: left;
  border: 1px solid $color-border;
  padding: $space-one $space-two;
}

.ui-notification-text {
  margin: 0;
}

.ui-refresh-button {
  color: $primary-color;
  font-weight: bold;
  font-size: $font-size-small;
}

.ui-notification-icon {
  font-size: $font-size-mega;
  color: $color-gray;
}

.ui-close-icon {
  font-size: $font-size-large;
  color: $color-gray;
}
</style>
