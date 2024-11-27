<script setup>
import { computed } from 'vue';
const { strong } = defineProps({
  strong: {
    type: Boolean,
    default: false,
  },
});

const borderClass = computed(() => {
  return strong ? 'border-n-strong' : 'border-n-weak';
});
</script>

<template>
  <div class="absolute">
    <ul
      class="text-sm bg-n-slate-3 backdrop-blur-[100px] border rounded-xl shadow-sm py-2 n-dropdown-body gap-2 grid list-none px-2 reset-base"
      :class="borderClass"
    >
      <slot />
    </ul>
  </div>
</template>
