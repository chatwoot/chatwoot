<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_VARIANTS } from '../constants';

const { attachments, variant } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const textClass = computed(() => {
  const textClassMap = {
    [MESSAGE_VARIANTS.AGENT]: 'text-[rgb(var(--bubble-agent-text))]',
    [MESSAGE_VARIANTS.USER]: 'text-[rgb(var(--bubble-user-text))]',
    [MESSAGE_VARIANTS.PRIVATE]: 'text-[rgb(var(--bubble-private-text))]',
    [MESSAGE_VARIANTS.BOT]: 'text-[rgb(var(--bubble-bot-text))]',
  };
  return textClassMap[variant.value] || 'text-[rgb(var(--bubble-agent-text))]';
});
</script>

<template>
  <BaseBubble class="bg-transparent" data-bubble-name="audio">
    <AudioChip
      :attachment="attachment"
      class="p-2 skip-context-menu"
      :class="textClass"
    />
  </BaseBubble>
</template>
