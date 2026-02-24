<script setup>
defineProps({
  message: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="w-full mb-4 flex items-center justify-start">
    <div
      v-dompurify-html="message"
      class="px-4 py-3 bg-white max-w-4xl text-slate-700 leading-6 text-sm rounded-md inline-block border border-slate-100"
    />
  </div>
</template>
