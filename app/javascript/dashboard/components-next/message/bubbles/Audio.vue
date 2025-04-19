<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useMessageContext } from '../provider.js';

const { attachments, content: messageContent } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});
</script>

<template>
  <BaseBubble class="bg-transparent" data-bubble-name="audio">
    <AudioChip
      :attachment="attachment"
      :message-content="messageContent"
      class="p-2 text-n-slate-12 skip-context-menu"
    />
  </BaseBubble>
</template>
