<script setup>
import { useToggle } from '@vueuse/core';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  defaultOpen: {
    type: Boolean,
    default: true,
  },
});

const [isOpen, toggle] = useToggle(props.defaultOpen);
</script>

<template>
  <div
    v-bind="$attrs"
    class="flex items-center justify-between w-full cursor-pointer pb-2 pt-4 border-t border-n-weak"
    @click="toggle()"
  >
    <span class="text-heading-2 text-n-slate-12 w-full">
      {{ title }}
    </span>
  </div>
  <div v-if="isOpen" class="w-full space-y-4 pt-4 mb-4">
    <slot />
  </div>
</template>
