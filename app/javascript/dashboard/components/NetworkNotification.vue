<template>
  <transition name="network-notification-fade" tag="div">
    <div class="ui-notification-container" v-show="show">
      <div class="ui-notification">
        <i class="ui-notification-icon icon ion-radio-waves" />
        <p class="ui-notification-text">
          Disconnected from chatwoot
        </p>
        <button class="ui-refresh-button" @click="refreshPage()">
          Refresh
        </button>
        <button class="ui-close-button" @click="closeModal()">
          <i class="ui-close-icon icon ion-ios-close-outline" />
        </button>
      </div>
    </div>
  </transition>
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

    closeModal() {
      this.show = false;
    },
  },
};
</script>
