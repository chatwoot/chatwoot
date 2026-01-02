<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    src: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    isComingSoon: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<template>
  <button
    class="relative bg-n-background cursor-pointer flex flex-col justify-end transition-all duration-200 ease-in py-6 px-0 items-center border border-solid border-n-weak hover:border-n-brand hover:shadow-md hover:z-50 disabled:opacity-60 min-h-[140px] rounded-md"
  >
    <img :src="src" :alt="title" draggable="false" class="w-1/2 my-4 mx-auto max-w-24" />
    <h3 class="text-n-slate-12 text-base font-medium text-center capitalize mt-3">
      {{ title }}
    </h3>

    <div
      v-if="isComingSoon"
      class="absolute inset-0 flex items-center justify-center backdrop-blur-[2px] rounded-md bg-gradient-to-br from-n-background/90 via-n-background/70 to-n-background/95"
    >
      <span class="text-n-slate-12 font-medium text-base">
        {{ $t('CHANNEL_SELECTOR.COMING_SOON') }} 🚀
      </span>
    </div>
  </button>
</template>

<style scoped lang="scss">
.inactive {
  img {
    filter: grayscale(100%);
  }

  &:hover {
    @apply border-n-strong shadow-none cursor-not-allowed;
  }
}
</style>
