<template>
  <transition name="network-notification-fade" tag="div">
    <div class="ui-notification-container" v-show="show">
      <div class="ui-notification">
        <svg class="ui-notification-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636a9 9 0 010 12.728m0 0l-2.829-2.829m2.829 2.829L21 21M15.536 8.464a5 5 0 010 7.072m0 0l-2.829-2.829m-4.243 2.829a4.978 4.978 0 01-1.414-2.83m-1.414 5.658a9 9 0 01-2.167-9.238m7.824 2.167a1 1 0 111.414 1.414m-1.414-1.414L3 3m8.293 8.293l1.414 1.414"></path></svg>
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
