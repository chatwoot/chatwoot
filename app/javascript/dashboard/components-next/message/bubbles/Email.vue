<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

const props = defineProps({
  content: {
    type: String,
    required: true,
  },
  contentAttributes: {
    type: Object,
    default: () => ({}),
  },
});

const contentToShow = computed(() => {
  return props.contentAttributes?.email?.htmlContent?.full ?? props.content;
});
</script>

<template>
  <BaseBubble class="w-full">
    <div class="p-4 prose prose-sm max-w-none" v-html="contentToShow" />
  </BaseBubble>
</template>
