<script setup>
import { computed } from 'vue';
const { strong } = defineProps({
  // Use strong prop when this dropdown is stacked inside another dropdown
  // Chrome has issues with stacked backdrop-blur, so we need an extra blur layer when stacked
  // Also, stacked dropdowns should have a strong border
  strong: {
    type: Boolean,
    default: false,
  },
});

const borderClass = computed(() => {
  return strong ? 'border-n-strong' : 'border-n-weak';
});

const beforeClass = computed(() => {
  if (!strong) return '';

  // Add extra blur layer only when strong prop is true, as a hack for Chrome's stacked backdrop-blur limitation
  // https://issues.chromium.org/issues/40835530
  return "before:content-['\x00A0'] before:absolute before:bottom-0 before:left-0 before:w-full before:h-full before:backdrop-contrast-70 before:backdrop-blur-sm before:z-0 [&>*]:relative";
});
</script>

<template>
  <div class="absolute">
    <ul
      class="text-sm bg-n-alpha-3 backdrop-blur-[100px] border rounded-xl shadow-sm py-2 n-dropdown-body gap-2 grid list-none px-2 reset-base relative"
      :class="[borderClass, beforeClass]"
    >
      <slot />
    </ul>
  </div>
</template>
