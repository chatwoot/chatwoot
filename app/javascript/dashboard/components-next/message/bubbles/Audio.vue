<script setup>
import { computed, ref } from 'vue';
import BaseBubble from './Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useMessageContext } from '../provider.js';
import MessageApi from 'dashboard/api/inbox/message';

const { attachments, id, conversationId } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const isTranscribing = ref(false);

const handleTranscribe = async () => {
  if (isTranscribing.value) return;
  isTranscribing.value = true;
  try {
    await MessageApi.transcribeAudio(conversationId.value, id.value);
  } catch {
    // transcription error handled silently; user can retry
  } finally {
    isTranscribing.value = false;
  }
};
</script>

<template>
  <BaseBubble class="bg-transparent" data-bubble-name="audio">
    <AudioChip
      :attachment="attachment"
      :is-transcribing="isTranscribing"
      :on-transcribe="
        !attachment?.transcribedText ? handleTranscribe : undefined
      "
      class="p-2 text-n-slate-12 skip-context-menu"
    />
  </BaseBubble>
</template>
