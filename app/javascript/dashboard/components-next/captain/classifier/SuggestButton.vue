<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  isActive: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['click']);
</script>

<template>
  <NextButton
    v-tooltip.top="$t('CONVERSATION.SUGGESTIONS.SUGGEST')"
    :variant="isActive ? 'faded' : 'ghost'"
    blue
    xs
    icon="i-ph-sparkle-fill"
    class="flex-shrink-0 !h-5 !w-5 !text-sm !text-n-iris-10 hover:enabled:!bg-n-iris-3 hover:enabled:!text-n-iris-11"
    :class="{
      '!bg-n-iris-3 !text-n-iris-11': isActive,
      'animate-twinkle': isLoading,
    }"
    @click="emit('click')"
  />
</template>
