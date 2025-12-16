<script setup>
import Icon from 'next/icon/Icon.vue';
</script>

<template>
  <Icon v-once icon="i-woot-captain" class="jumping-logo" />
</template>

<style scoped>
.jumping-logo {
  transform-origin: center bottom;
  animation: jump 1s cubic-bezier(0.28, 0.84, 0.42, 1) infinite;
  will-change: transform;
}

@keyframes jump {
  0% {
    transform: translateY(0) scale(1, 1);
  }
  20% {
    transform: translateY(0) scale(1.05, 0.95);
  }
  50% {
    transform: translateY(-5px) scale(0.95, 1.05);
  }
  80% {
    transform: translateY(0) scale(1.02, 0.98);
  }
  100% {
    transform: translateY(0) scale(1, 1);
  }
}
</style>
