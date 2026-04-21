<script setup>
defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="bg-s-subtle text-s-primary rounded-xl p-3 max-w-80">
    <span v-dompurify-html="message.content" class="prose prose-bubble" />
  </div>
</template>
