<template>
  <transition-group name="toast-fade" tag="div" class="ui-snackbar-container">
    <woot-snackbar
      v-for="snackMessage in snackMessages"
      :key="snackMessage.key"
      :message="snackMessage.message"
    />
  </transition-group>
</template>

<script>
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
    bus.$on('newToastMessage', this.onNewToastMessage);
  },
  beforeDestroy() {
    bus.$off('newToastMessage', this.onNewToastMessage);
  },
  methods: {
    onNewToastMessage(message) {
      this.snackMessages.push({ key: new Date().getTime(), message });
      window.setTimeout(() => {
        this.snackMessages.splice(0, 1);
      }, this.duration);
    },
  },
};
</script>
