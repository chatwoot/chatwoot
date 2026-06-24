<script setup>
import { computed, toRef } from 'vue';
import { usePanelIaState } from 'dashboard/composables/usePanelIaState';

const props = defineProps({
  chat: {
    type: Object,
    required: true,
  },
  variant: {
    type: String,
    default: 'vertical',
    validator: value => ['vertical', 'horizontal'].includes(value),
  },
});

const chatRef = toRef(props, 'chat');
const { showIndicator, indicatorClass, label, config } =
  usePanelIaState(chatRef);

const indicatorLayoutClass = computed(() => {
  if (props.variant === 'horizontal') {
    return 'h-1 w-full shrink-0';
  }
  return 'absolute left-0 top-0 bottom-0 w-[3px] z-10';
});

const pulseClass = computed(() =>
  config.value?.pulseIndicator ? ' animate-pulse' : ''
);
</script>

<template>
  <div
    v-if="showIndicator && indicatorClass"
    v-tooltip="label"
    class="pointer-events-none"
    :class="[indicatorLayoutClass, indicatorClass, pulseClass]"
    role="status"
    :aria-label="label"
  />
</template>
