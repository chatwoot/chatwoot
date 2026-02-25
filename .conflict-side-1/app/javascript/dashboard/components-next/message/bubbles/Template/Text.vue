<script setup>
defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="bg-n-alpha-2 text-n-slate-12 rounded-xl p-3 max-w-80">
    <span v-dompurify-html="message.content" class="prose prose-bubble" />
  </div>
</template>
