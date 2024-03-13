<script setup>
defineProps({
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
  isLeftAligned: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    class="flex items-end justify-center gap-3 w-80"
    :class="{ 'flex-row-reverse ml-14': !isLeftAligned }"
  >
    <div class="bg-white rounded-full shrink-0">
      <img
        :src="authorImage"
        class="w-12 h-12 border rounded-full shadow-sm dark:border-none border-slate-200 dark:shadow-none"
      />
    </div>
    <div class="text-woot-900 dark:text-woot-100">
      <div
        class="w-[360px] shrink-0 flex flex-col mt-4 dark:bg-[#0F1720] bg-[#FBFDFF] p-4 rounded-2xl border border-solid border-woot-100 dark:border-woot-800"
      >
        <p class="text-sm leading-6 tracking-wide">
          {{ reviewContent }}
        </p>
      </div>
      <div class="px-1 mt-2" :class="{ 'text-right': !isLeftAligned }">
        <div class="text-sm font-medium">
          {{ authorName }}, {{ authorDesignation }}
        </div>
      </div>
    </div>
  </div>
</template>
