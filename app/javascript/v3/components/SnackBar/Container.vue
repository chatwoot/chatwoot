<script>
import { BUS_EVENTS } from 'shared/constants/busEvents';
import SnackbarItem from './Item.vue';
import { emitter } from 'shared/helpers/mitt';

export default {
  components: { SnackbarItem },
  props: {
    duration: {
      type: Number,
      default: 2500,
    },
  },

  data() {
    return {
      snackbarAlertMessages: [],
    };
  },

  mounted() {
    emitter.on(BUS_EVENTS.SHOW_TOAST, this.onNewToastMessage);
  },
  unmounted() {
    emitter.off(BUS_EVENTS.SHOW_TOAST, this.onNewToastMessage);
  },
  methods: {
    onNewToastMessage({ message, action }) {
      const duration = action?.duration || this.duration;
      const snackbarAlertMessage = {
        key: new Date().getTime(),
        message,
        action,
      };

      this.snackbarAlertMessages.push(snackbarAlertMessage);
      window.setTimeout(() => {
        const messageIndex =
          this.snackbarAlertMessages.indexOf(snackbarAlertMessage);
        if (messageIndex !== -1) {
          this.snackbarAlertMessages.splice(messageIndex, 1);
        }
      }, duration);
    },
  },
};
</script>

<template>
  <transition-group
    name="toast-fade"
    tag="div"
    class="fixed left-0 right-0 mx-auto overflow-hidden text-center top-10 z-50 max-w-[40rem]"
  >
    <SnackbarItem
      v-for="snackbarAlertMessage in snackbarAlertMessages"
      :key="snackbarAlertMessage.key"
      :message="snackbarAlertMessage.message"
      :action="snackbarAlertMessage.action"
    />
  </transition-group>
</template>
