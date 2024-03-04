<template>
  <div
    class="flex items-end justify-center w-80 gap-3"
    :class="{ 'flex-row-reverse ml-14': !isLeftAligned }"
  >
    <div class="bg-white rounded-full shrink-0">
      <img :src="authorImage" class="h-12 w-12 rounded-full" />
    </div>
    <div class="text-woot-900 dark:text-woot-100">
      <div
        class="w-[360px] shrink-0 flex flex-col mt-4 dark:bg-[#0F1720] bg-[##FBFDFF] p-4 rounded-2xl border border-solid border-woot-100 dark:border-woot-800"
      >
        <p class="text-sm tracking-wide leading-6">
          {{ reviewContent }}
        </p>
      </div>
      <div class="mt-2 px-1" :class="{ 'text-right': !isLeftAligned }">
        <div class="text-sm">{{ authorName }}, {{ authorDesignation }}</div>
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
    isLeftAligned: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
