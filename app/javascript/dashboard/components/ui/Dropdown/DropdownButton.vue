<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  buttonText: {
    type: String,
    default: '',
  },
  trailingIcon: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <Button
    ghost
    slate
    sm
    class="relative"
    :icon="icon"
    :trailing-icon="trailingIcon"
  >
    <span class="min-w-0 truncate">{{ buttonText }}</span>
    <slot name="dropdown" />
  </Button>
</template>
