<script setup>
import { useToggle } from '@vueuse/core';
import { provideDropdownContext } from './provider.js';

const emit = defineEmits(['close']);
const [isOpen, toggle] = useToggle(false);

const closeMenu = () => {
  if (isOpen.value) {
    emit('close');
    toggle(false);
  }
};

provideDropdownContext({
  isOpen,
  toggle,
  closeMenu,
});
</script>

<template>
  <div class="relative z-20 space-y-2">
    <slot name="trigger" :is-open :toggle="() => toggle()" />
    <div v-if="isOpen" v-on-clickaway="closeMenu" class="absolute">
      <slot />
    </div>
  </div>
</template>
