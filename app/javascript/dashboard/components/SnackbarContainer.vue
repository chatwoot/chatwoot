<script>
import WootSnackbar from './Snackbar.vue';
import { emitter } from 'shared/helpers/mitt';

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
    emitter.on('newToastMessage', this.onNewToastMessage);
  },
  unmounted() {
    emitter.off('newToastMessage', this.onNewToastMessage);
  },
  methods: {
    onNewToastMessage({ message, action }) {
      this.snackMessages.push({
        key: new Date().getTime(),
        message,
        action,
      });
      window.setTimeout(() => {
        this.snackMessages.splice(0, 1);
      }, this.duration);
    },
  },
};
</script>

<template>
  <transition-group
    name="toast-fade"
    tag="div"
    class="left-0 my-0 mx-auto max-w-[25rem] overflow-hidden absolute right-0 text-center top-4 z-[9999]"
  >
    <WootSnackbar
      v-for="snackMessage in snackMessages"
      :key="snackMessage.key"
      :message="snackMessage.message"
      :action="snackMessage.action"
    />
  </transition-group>
</template>
