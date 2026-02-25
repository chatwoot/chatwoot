<script setup>
defineProps({
  reviewContent: { type: String, default: '' },
  authorImage: { type: String, default: '' },
  authorName: { type: String, default: '' },
  authorDesignation: { type: String, default: '' },
});
</script>

<template>
  <div class="flex flex-col items-start">
    <svg
      class="w-10 h-10 text-n-slate-7 mb-6"
      viewBox="0 0 40 40"
      fill="currentColor"
    >
      <path
        d="M10.7 28.3c-1.4-1.2-2.1-3-2.1-5.4 0-2.3.8-4.6 2.4-6.8 1.6-2.2 3.8-3.9 6.6-5.1l1.2 2.1c-2.2 1.2-3.7 2.4-4.6 3.6-.9 1.2-1.3 2.5-1.2 3.8.3-.1.7-.2 1.2-.2 1.3 0 2.4.4 3.3 1.3.9.9 1.3 2 1.3 3.3 0 1.4-.5 2.5-1.4 3.4-.9.9-2.1 1.4-3.5 1.4-1.5 0-2.7-.5-3.2-1.4zm15 0c-1.4-1.2-2.1-3-2.1-5.4 0-2.3.8-4.6 2.4-6.8 1.6-2.2 3.8-3.9 6.6-5.1l1.2 2.1c-2.2 1.2-3.7 2.4-4.6 3.6-.9 1.2-1.3 2.5-1.2 3.8.3-.1.7-.2 1.2-.2 1.3 0 2.4.4 3.3 1.3.9.9 1.3 2 1.3 3.3 0 1.4-.5 2.5-1.4 3.4-.9.9-2.1 1.4-3.5 1.4-1.5 0-2.7-.5-3.2-1.4z"
      />
    </svg>
    <p
      class="text-lg text-n-slate-12 leading-relaxed whitespace-pre-line tracking-tight"
    >
      {{ reviewContent }}
    </p>
    <div class="flex items-center mt-8">
      <img
        :src="authorImage"
        :alt="authorName"
        class="w-11 h-11 rounded-full object-cover"
      />
      <div class="ml-3">
        <div class="text-base font-medium text-n-slate-12">
          {{ authorName }}
        </div>
        <div class="text-sm text-n-slate-10">{{ authorDesignation }}</div>
      </div>
    </div>
  </div>
</template>
