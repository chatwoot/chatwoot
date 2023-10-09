<script setup>
import { computed } from 'vue';
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

const { content } = defineProps({
  content: {
    type: String,
    default: '',
  },
});

const cleanedContent = computed(() => extractTextFromMarkdown(content));

const defaultEmptyMessage = this.$t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND');
</script>

<template>
  <div
    class="p-2 -mx-2 overflow-hidden rounded-md bg-woot-600 line-clamp-3 min-w-[15rem] mb-2 cursor-pointer"
    @click="$emit('click')"
  >
    <template v-if="content">
      {{ cleanedContent }}
    </template>
    <template v-else> {{ defaultEmptyMessage }} </template>
  </div>
</template>
