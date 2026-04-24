<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  label: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="flex items-center gap-2 px-3 pt-4 pb-1 select-none pointer-events-none"
  >
    <Icon v-if="icon" :icon="icon" class="size-3.5 text-white/[0.35]" />
    <span
      class="text-[10px] font-semibold uppercase tracking-[0.08em] flex-grow text-white/[0.35]"
    >
      {{ label }}
    </span>
  </div>
</template>
