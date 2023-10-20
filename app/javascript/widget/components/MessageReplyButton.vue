<template>
  <button
    class="p-1.5 mb-1 rounded-full dark:text-slate-500 dark:bg-slate-900 text-slate-600 bg-slate-100 hover:text-slate-800 group-hover:opacity-100 opacity-0 sm:opacity-0"
    @click="toggleReply"
  >
    <FluentIcon icon="arrow-reply" size="12" class="flex-shrink-0" />
  </button>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  name: 'MessageReplyButton',
  components: { FluentIcon },
  props: {
    message: {
      type: Object,
      default: () => {},
    },
  },
  methods: {
    toggleReply() {
      bus.$emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.message);
    },
  },
};
</script>
