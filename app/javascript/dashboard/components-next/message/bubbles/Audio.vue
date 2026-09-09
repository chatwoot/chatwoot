<script setup>
import { computed, onMounted } from 'vue';
import BaseBubble from './Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry({
  mediaType: 'audio',
});

onMounted(() => {
  if (attachment.value?.dataUrl) {
    loadWithRetry(attachment.value.dataUrl);
  }
});
</script>

<template>
  <BaseBubble class="bg-transparent" data-bubble-name="audio">
    <AudioChip
      v-if="isLoaded || hasError"
      :has-error="hasError"
      :attachment="attachment"
      class="p-2 text-n-slate-12 skip-context-menu"
    />
  </BaseBubble>
</template>
