<script setup>
import AISuggestions from './conversation/AISuggestions.vue';

defineProps({
  conversation: {
    type: Object,
    default: () => ({}),
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
});
</script>

<template>
  <AISuggestions :conversation="conversation" :contact="contact" />
</template>
