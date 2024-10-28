<script setup>
import { useToggle } from '@vueuse/core';

const emit = defineEmits(['close']);
const [isOpen, toggle] = useToggle(false);

const closeMenu = () => {
  if (isOpen.value) {
    emit('close');
    toggle(false);
  }
};
</script>

<template>
  <div class="relative z-20 space-y-2">
    <slot name="trigger" :is-open :toggle="() => toggle()" />
    <div v-show="isOpen" v-on-clickaway="closeMenu" class="absolute">
      <slot />
    </div>
  </div>
</template>
