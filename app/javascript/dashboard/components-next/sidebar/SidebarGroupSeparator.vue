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
    class="flex items-center gap-2 px-3 pt-4 pb-1 text-s-muted select-none pointer-events-none"
  >
    <Icon v-if="icon" :icon="icon" class="size-3.5" />
    <span
      class="text-[11px] font-semibold uppercase tracking-wider flex-grow"
    >
      {{ label }}
    </span>
  </div>
</template>
