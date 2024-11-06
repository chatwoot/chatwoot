<script setup>
import { ref } from 'vue';
import { provideDropdownContext } from './provider.js';

const emit = defineEmits(['close']);

const isOpen = ref(false);

const closeMenu = () => {
  if (isOpen.value) {
    emit('close');
    isOpen.value = false;
  }
};

const toggle = newState => {
  if (newState !== undefined) {
    isOpen.value = newState;
  } else {
    isOpen.value = !isOpen.value;
  }
};

provideDropdownContext({
  isOpen,
  toggle,
  closeMenu,
});
</script>

<template>
  <div class="relative space-y-2">
    <slot name="trigger" :is-open :toggle="() => toggle()" />
    <div v-if="isOpen" v-on-clickaway="closeMenu" class="absolute z-20">
      <slot />
    </div>
  </div>
</template>
