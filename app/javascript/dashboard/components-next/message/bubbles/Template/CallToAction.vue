<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  message: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div class="text-s-primary max-w-80 flex flex-col gap-2.5">
    <div class="p-3 bg-s-subtle rounded-xl">
      <span
        v-dompurify-html="message.content"
        class="prose prose-bubble font-medium text-sm"
      />
    </div>
    <div class="flex gap-2">
      <Button label="Call us" slate class="!text-s-brand-text w-full" />
      <Button label="Visit our website" slate class="!text-s-brand-text w-full" />
    </div>
  </div>
</template>
