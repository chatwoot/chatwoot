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
  <div
    class="bg-s-subtle divide-y divide-s-border-strong text-s-primary rounded-xl max-w-80"
  >
    <div class="p-3">
      <span
        v-dompurify-html="message.content"
        class="prose prose-bubble font-medium text-sm"
      />
    </div>
    <div class="p-3 flex items-center justify-center">
      <Button label="See options" link class="hover:!no-underline" />
    </div>
  </div>
</template>
