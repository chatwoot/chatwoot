<script>
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

export default {
  props: {
    size: {
      type: String,
      default: 'small',
    },
  },
  methods: {
    onMenuItemClick() {
      emitter.emit(BUS_EVENTS.TOGGLE_SIDEMENU);
    },
  },
};
</script>

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
