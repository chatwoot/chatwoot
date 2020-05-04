<template>
  <transition-group name="toast-fade" tag="div" class="ui-snackbar-container">
    <woot-snackbar
      v-for="snackMessage in snackMessages"
      :key="snackMessage"
      :message="snackMessage"
    />
  </transition-group>
</template>

<script>
/* global bus */
import WootSnackbar from './Snackbar';

export default {
  components: {
    WootSnackbar,
  },
  props: {
    duration: {
      type: Number,
      default: 2500,
    },
  },

  data() {
    return {
      snackMessages: [],
    };
  },

  mounted() {
    bus.$on('newToastMessage', message => {
      this.snackMessages.push(message);
      window.setTimeout(() => {
        this.snackMessages.splice(0, 1);
      }, this.duration);
    });
  },
};
</script>
