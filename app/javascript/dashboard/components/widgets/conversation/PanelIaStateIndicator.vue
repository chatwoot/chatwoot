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
    default: 'row',
    validator: value => ['row', 'vertical', 'horizontal'].includes(value),
  },
});

const chatRef = toRef(props, 'chat');
const { showIndicator, indicatorClass, label, config } =
  usePanelIaState(chatRef);

const wrapperLayoutClass = computed(() => {
  if (props.variant === 'horizontal') {
    return 'h-1 w-full shrink-0';
  }
  if (props.variant === 'vertical') {
    return 'absolute inset-y-0 start-0 w-[3px] z-10';
  }
  // Soft full-row wash (default)
  return 'absolute inset-0 z-0 pointer-events-none';
});

const pulseClass = computed(() =>
  config.value?.pulseIndicator ? ' animate-pulse' : ''
);
</script>

<template>
  <div
    v-show="showIndicator && indicatorClass"
    v-tooltip="variant === 'row' ? undefined : label"
    :class="wrapperLayoutClass"
  >
    <div
      class="h-full w-full"
      :class="[
        indicatorClass,
        pulseClass,
        variant === 'row' ? 'pointer-events-none' : '',
      ]"
      role="status"
      :aria-label="label"
    />
  </div>
</template>
