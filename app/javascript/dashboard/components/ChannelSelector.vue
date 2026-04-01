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
  disabled: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <button
    type="button"
    class="group relative flex cursor-pointer flex-col items-start gap-6 rounded-xl border border-transparent bg-surface-container-low p-6 text-start transition-all duration-300"
    :class="{
      'hover:border-secondary/30 hover:shadow-[0_0_20px_rgba(70,221,183,0.1)]':
        !isComingSoon && !disabled,
      'cursor-not-allowed opacity-50': disabled && !isComingSoon,
      'cursor-not-allowed': isComingSoon,
    }"
    :disabled="disabled || isComingSoon"
  >
    <div
      class="flex size-12 items-center justify-center rounded-lg bg-surface-container-high transition-transform duration-300"
      :class="{
        'group-hover:scale-110': !disabled && !isComingSoon,
      }"
    >
      <Icon :icon="icon" class="size-7 text-secondary" />
    </div>

    <div class="flex flex-col items-start gap-1">
      <h3 class="text-lg font-bold leading-snug text-on-surface">
        {{ title }}
      </h3>
      <p class="text-sm leading-snug text-on-surface-variant">
        {{ description }}
      </p>
    </div>

    <div
      v-if="isComingSoon"
      class="absolute inset-0 flex cursor-not-allowed items-center justify-center rounded-xl bg-gradient-to-br from-surface/90 via-surface/75 to-surface/95 backdrop-blur-[2px]"
    >
      <span class="text-sm font-medium text-on-surface">
        {{ $t('CHANNEL_SELECTOR.COMING_SOON') }} 🚀
      </span>
    </div>
  </button>
</template>
