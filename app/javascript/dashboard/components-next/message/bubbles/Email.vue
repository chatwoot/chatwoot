<script setup>
import BaseBubble from 'next/message/bubbles/Base.vue';

defineProps({
  content: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <BaseBubble class="w-full">
    <div class="p-4 prose prose-sm max-w-none" v-html="content" />
  </BaseBubble>
</template>
