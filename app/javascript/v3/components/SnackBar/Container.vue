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
      this.snackbarAlertMessages.push({
        key: new Date().getTime(),
        message,
        action,
      });
      window.setTimeout(() => {
        this.snackbarAlertMessages.splice(0, 1);
      }, this.duration);
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
