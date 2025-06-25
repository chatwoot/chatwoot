<script setup>
defineProps({
  message: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="w-full mb-4 flex items-center justify-end">
    <div
      v-dompurify-html="message"
      class="px-4 py-3 bg-woot-400 text-white text-sm rounded-md inline-block"
    />
  </div>
</template>
