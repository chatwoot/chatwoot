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

<template>
  <div
    class="flex flex-col items-start justify-center p-6 w-80 bg-n-background rounded-lg drop-shadow-md"
  >
    <p class="text-sm text-n-slate-12 tracking-normal">
      {{ reviewContent }}
    </p>
    <div class="flex items-center mt-4 text-n-slate-12">
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
