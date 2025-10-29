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
    class="bg-n-alpha-2 text-n-slate-12 rounded-xl p-3 max-w-80 flex flex-col gap-2"
  >
    <!-- Header Text -->
    <div v-if="message.title" class="font-bold text-base">
      {{ message.title }}
    </div>

    <!-- Body Content -->
    <div v-if="message.content" class="prose prose-bubble font-medium text-sm">
      <span v-dompurify-html="message.content" />
    </div>

    <!-- Footer Text -->
    <div v-if="message.footer" class="text-xs text-n-slate-11 opacity-70">
      {{ message.footer }}
    </div>
  </div>
</template>
