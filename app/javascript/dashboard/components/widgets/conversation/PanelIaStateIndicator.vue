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

const wrapperLayoutClass = computed(() => {
  if (props.variant === 'horizontal') {
    return 'h-1 w-full shrink-0';
  }
  return 'absolute inset-y-0 start-0 w-[3px] z-10';
});

const pulseClass = computed(() =>
  config.value?.pulseIndicator ? ' animate-pulse' : ''
);
</script>

<template>
  <div
    v-show="showIndicator && indicatorClass"
    v-tooltip="label"
    :class="wrapperLayoutClass"
  >
    <div
      class="pointer-events-none h-full w-full"
      :class="[indicatorClass, pulseClass]"
      role="status"
      :aria-label="label"
    />
  </div>
</template>
