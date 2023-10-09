<script setup>
import { computed } from 'vue';
import { extractTextFromMarkdown } from 'dashboard/helper/editorHelper';

const props = defineProps({
  content: {
    type: String,
    default: '',
  },
  defaultEmptyMessage: {
    type: String,
    required: true,
  },
});

const cleanedContent = computed(() => extractTextFromMarkdown(props.content));
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
