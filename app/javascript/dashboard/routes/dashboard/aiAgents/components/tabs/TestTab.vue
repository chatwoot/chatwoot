<script setup>
import ChatPreviewPanel from '../preview/ChatPreviewPanel.vue';

defineProps({
  agent: { type: Object, required: true },
});
</script>

<template>
  <div class="flex flex-col h-[calc(100vh-12rem)] max-w-2xl">
    <ChatPreviewPanel :agent="agent" />
  </div>
</template>
