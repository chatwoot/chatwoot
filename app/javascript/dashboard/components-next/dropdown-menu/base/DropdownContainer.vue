<script setup>
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
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
    <div v-if="isOpen" v-on-click-outside="closeMenu" class="absolute z-20">
      <slot />
    </div>
  </div>
</template>
