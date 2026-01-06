<script setup>
defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div
    class="bg-n-alpha-2 text-n-slate-12 rounded-xl flex flex-col gap-2.5 p-3 max-w-80"
  >
    <img :src="message.image_url" class="max-h-44 rounded-lg w-full" />
    <span
      v-dompurify-html="message.content"
      class="prose prose-bubble font-medium text-sm"
    />
  </div>
</template>
