<template>
  <span
    v-if="priority"
    v-tooltip="{
      content: tooltipText,
      delay: { show: 1500, hide: 0 },
      hideOnClick: true,
    }"
    class="conversation-priority-mark"
    :class="{ urgent: priority === CONVERSATION_PRIORITY.URGENT }"
  >
    <fluent-icon
      :icon="`priority-${priority.toLowerCase()}`"
      size="14"
      view-box="0 0 14 14"
    />
  </span>
</template>

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
  },
};
</script>

<style scoped lang="scss">
.conversation-priority-mark {
  align-items: center;
  background: var(--s-50);
  border-radius: var(--border-radius-small);
  color: var(--s-600);
  display: inline-flex;
  width: var(--space-snug);

  &.urgent {
    background: var(--r-500);
    color: var(--w-25);
  }
}
</style>
