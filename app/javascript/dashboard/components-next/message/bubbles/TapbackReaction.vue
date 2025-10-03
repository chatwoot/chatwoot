<script setup>
import { computed } from 'vue';

const props = defineProps({
  content: { type: String, required: true },
  contentAttributes: { type: Object, default: () => ({}) },
});

const tapbackEmoji = computed(() => {
  return props.contentAttributes?.tapback_emoji || '👍';
});

const referencedText = computed(() => {
  return props.contentAttributes?.tapback_referenced_text || '';
});

const displayText = computed(() => {
  // For standard tapbacks with referenced text, show emoji and reference
  if (referencedText.value) {
    return `Reacted ${tapbackEmoji.value} to "${referencedText.value}"`;
  }
  // Otherwise, show the original content
  return props.content;
});
</script>

<template>
  <div
    class="flex items-center gap-2 rounded-lg bg-slate-50 px-3 py-2 text-sm text-slate-600 dark:bg-slate-800 dark:text-slate-300"
  >
    <span class="text-lg">{{ tapbackEmoji }}</span>
    <span class="italic">{{ displayText }}</span>
  </div>
</template>
