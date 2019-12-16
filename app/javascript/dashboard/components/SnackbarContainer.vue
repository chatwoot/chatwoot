<template>
  <transition-group name="toast-fade" tag="div" class="ui-snackbar-container">
    <woot-snackbar :message="snackMessage" v-for="snackMessage in snackMessages" v-bind:key="snackMessage" />
  </transition-group>
</template>

<script>
/* global bus */
import WootSnackbar from './Snackbar';

export default {
  props: {
    duration: {
      default: 2500,
    },
  },

  data() {
    return {
      snackMessages: [],
    };
  },

  mounted() {
    bus.$on('newToastMessage', (message) => {
      this.snackMessages.push(message);
      window.setTimeout(() => {
        this.snackMessages.splice(0, 1);
      }, this.duration);
    });
  },

  components: {
    WootSnackbar,
  },
};
</script>
