<script setup>
import { computed } from 'vue';
import { CONVERSATION_PRIORITY } from 'shared/constants/messages';

import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  priority: {
    type: String,
    default: '',
  },
  showEmpty: {
    type: Boolean,
    default: false,
  },
});

const icons = {
  [CONVERSATION_PRIORITY.URGENT]: 'i-woot-priority-urgent',
  [CONVERSATION_PRIORITY.HIGH]: 'i-woot-priority-high',
  [CONVERSATION_PRIORITY.MEDIUM]: 'i-woot-priority-medium',
  [CONVERSATION_PRIORITY.LOW]: 'i-woot-priority-low',
};

const iconName = computed(() => {
  if (props.priority && icons[props.priority]) {
    return icons[props.priority];
  }
  return props.showEmpty ? 'i-woot-priority-empty' : '';
});
</script>

<template>
  <Icon
    v-tooltip.top="{
      content: priority,
      delay: { show: 500, hide: 0 },
    }"
    :icon="iconName"
    class="size-4 text-n-slate-5"
  />
</template>
