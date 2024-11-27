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
  <BaseBubble>
    <span v-html="content" />
  </BaseBubble>
</template>
