<script setup>
import { computed } from 'vue';
import { Letter } from 'vue-letter';
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

const textToShow = computed(() => {
  return props.contentAttributes?.email?.textContent?.full ?? props.content;
});
</script>

<template>
  <BaseBubble class="w-full">
    <div class="p-3">
      <Letter
        class-name="prose prose-email"
        :html="contentToShow"
        :text="textToShow"
      />
    </div>
  </BaseBubble>
</template>
