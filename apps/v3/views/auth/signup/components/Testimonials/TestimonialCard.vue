<template>
  <div
    class="flex flex-col items-start justify-center p-6 w-80 bg-white rounded-lg drop-shadow-md dark:bg-slate-800"
  >
    <p class="text-sm text-slate-600 dark:text-woot-50 tracking-normal">
      {{ reviewContent }}
    </p>
    <div class="flex items-center mt-4 text-slate-700 dark:text-woot-50">
      <div class="bg-white rounded-full p-1">
        <img :src="authorImage" class="h-8 w-8 rounded-full" />
      </div>
      <div class="ml-2">
        <div class="text-sm font-medium">{{ authorName }}</div>
        <div class="text-xs">{{ authorDesignation }}</div>
      </div>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    reviewContent: {
      type: String,
      default: '',
    },
    authorImage: {
      type: String,
      default: '',
    },
    authorName: {
      type: String,
      default: '',
    },
    authorDesignation: {
      type: String,
      default: '',
    },
  },
};
</script>
