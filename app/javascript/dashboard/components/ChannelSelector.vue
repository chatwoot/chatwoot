<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    required: true,
  },
  isComingSoon: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <button
    class="relative bg-n-background cursor-pointer flex flex-col justify-end transition-all duration-200 ease-in -m-px py-4 px-0 items-center border border-solid border-n-weak hover:border-n-brand dark:hover:border-n-lightBrand hover:shadow-md hover:z-50 disabled:opacity-60"
  >
    <div
      class="flex size-10 items-center justify-center rounded-full bg-n-alpha-2"
    >
      <Icon :icon="icon" class="text-n-slate-10 size-6" />
    </div>

    <div class="flex flex-col items-start gap-1.5">
      <h3 class="text-n-slate-12 text-sm text-start font-medium capitalize">
        {{ title }}
      </h3>
      <p class="text-n-slate-11 text-start text-sm">
        {{ description }}
      </p>
    </div>

    <div
      v-if="isComingSoon"
      class="absolute inset-0 flex items-center justify-center backdrop-blur-[2px] rounded-2xl bg-gradient-to-br from-n-background/90 via-n-background/70 to-n-background/95 cursor-not-allowed"
    >
      <span class="text-n-slate-12 font-medium text-sm">
        {{ $t('CHANNEL_SELECTOR.COMING_SOON') }} 🚀
      </span>
    </div>
  </button>
</template>
