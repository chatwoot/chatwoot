<script setup>
import BaseBubble from './Base.vue';

defineProps({
  content: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <BaseBubble class="px-2 py-0.5" data-bubble-name="activity">
    <span v-html="content" />
  </BaseBubble>
</template>
