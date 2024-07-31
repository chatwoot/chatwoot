<template>
  <woot-button
    :size="size"
    variant="clear"
    color-scheme="secondary"
    class="-ml-3 text-black-900 dark:text-slate-300"
    icon="list"
    @click="onMenuItemClick"
  />
</template>

<script>
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  props: {
    size: {
      type: String,
      default: 'small',
    },
  },
  methods: {
    onMenuItemClick() {
      this.$emitter.emit(BUS_EVENTS.TOGGLE_SIDEMENU);
    },
  },
};
</script>
