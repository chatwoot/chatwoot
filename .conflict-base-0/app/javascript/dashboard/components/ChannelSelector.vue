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
    class="relative bg-n-solid-1 gap-6 cursor-pointer rounded-2xl flex flex-col justify-start transition-all duration-200 ease-in -m-px py-6 px-5 items-start border border-solid border-n-weak"
    :class="{
      'hover:enabled:border-n-blue-9 hover:enabled:shadow-md disabled:opacity-60 disabled:cursor-not-allowed':
        !isComingSoon,
      'cursor-not-allowed disabled:opacity-80': isComingSoon,
    }"
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
      class="absolute inset-0 flex items-center justify-center backdrop-blur-[2px] rounded-2xl bg-gradient-to-br from-n-surface-1/90 via-n-surface-1/70 to-n-surface-1/95 cursor-not-allowed"
    >
      <span class="text-n-slate-12 font-medium text-sm">
        {{ $t('CHANNEL_SELECTOR.COMING_SOON') }} 🚀
      </span>
    </div>
  </button>
</template>
