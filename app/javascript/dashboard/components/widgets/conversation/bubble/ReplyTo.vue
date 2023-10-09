<script setup>
import { computed } from 'vue';
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

const { content } = defineProps({
  content: {
    type: String,
    required: true,
  },
});

const cleanedContent = computed(() => extractTextFromMarkdown(content));
</script>

<template>
  <div
    class="p-2 -mx-2 overflow-hidden rounded-md bg-woot-600 line-clamp-3 min-w-[15rem] mb-2 cursor-pointer"
    @click="$emit('click')"
  >
    {{ cleanedContent }}
  </div>
</template>
