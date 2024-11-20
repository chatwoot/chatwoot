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
    class="shrink-0 rounded-sm inline-flex w-3.5 h-3.5"
    :class="{
      'bg-red-50 dark:bg-red-700 dark:bg-opacity-30 text-red-500 dark:text-red-600':
        isUrgent,
      'bg-slate-50 dark:bg-slate-700 text-slate-600 dark:text-slate-200':
        !isUrgent,
    }"
  >
    <fluent-icon
      :icon="`priority-${priority.toLowerCase()}`"
      size="14"
      view-box="0 0 14 14"
    />
  </span>
</template>
