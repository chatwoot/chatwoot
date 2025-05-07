<script setup>
import { computed } from 'vue';

defineProps({
  label: {
    type: String,
    default: 'Click me',
  },
});

// eslint-disable-next-line no-underscore-dangle
const store = window.__CHATWOOT_STORE__;

// Example of accessing store state
const currentUser = computed(() => {
  try {
    return store.getters.getCurrentUser;
  } catch (e) {
    return null;
  }
});

const handleClick = () => {};
</script>

<template>
  <button class="cha-button" @click="handleClick">
    {{ currentUser }} {{ label }}
  </button>
</template>

<style scoped>
.cha-button {
  @apply bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-md;
}
</style>
