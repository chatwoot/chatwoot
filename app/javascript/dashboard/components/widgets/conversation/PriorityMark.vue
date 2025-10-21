<script>
import { CONVERSATION_PRIORITY } from '../../../../shared/constants/messages';

export default {
  name: 'PriorityMark',
  props: {
    priority: {
      type: String,
      default: '',
      validate: value =>
        [...Object.values(CONVERSATION_PRIORITY), ''].includes(value),
    },
  },
  data() {
    return {
      CONVERSATION_PRIORITY,
    };
  },
  computed: {
    tooltipText() {
      return this.$t(
        `CONVERSATION.PRIORITY.OPTIONS.${this.priority.toUpperCase()}`
      );
    },
    isUrgent() {
      return this.priority === CONVERSATION_PRIORITY.URGENT;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <span
    v-if="priority"
    v-tooltip="{
      content: tooltipText,
      delay: { show: 1500, hide: 0 },
      hideOnClick: true,
    }"
    class="shrink-0 rounded-sm inline-flex items-center justify-center w-3.5 h-3.5"
    :class="{
      'bg-n-ruby-4 text-n-ruby-10': isUrgent,
      'bg-n-slate-4 text-n-slate-11': !isUrgent,
    }"
  >
    <fluent-icon
      :icon="`priority-${priority.toLowerCase()}`"
      :size="isUrgent ? 12 : 14"
      class="flex-shrink-0"
      view-box="0 0 14 14"
    />
  </span>
</template>
