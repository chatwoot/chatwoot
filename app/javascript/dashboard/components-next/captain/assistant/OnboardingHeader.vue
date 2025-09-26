<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  title: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="flex items-center justify-between gap-14 mt-3">
    <div class="flex flex-col items-start gap-4">
      <div
        class="p-2 flex items-center gap-1.5 rounded-[10px] border border-n-weak"
      >
        <Icon :icon="icon" class="size-4 text-n-slate-11" />
        <h3 class="text-n-slate-12 text-sm font-medium">{{ title }}</h3>
      </div>
      <p class="text-n-slate-12 text-lg leading-6 font-semibold">
        {{ subtitle }}
      </p>
      <p class="text-n-slate-11 text-sm">{{ description }}</p>
    </div>
    <slot />
  </div>
</template>
