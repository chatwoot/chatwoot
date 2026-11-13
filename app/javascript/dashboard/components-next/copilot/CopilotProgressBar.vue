<script setup>
defineProps({
  done: { type: Number, required: true },
  total: { type: Number, required: true },
});
</script>

<template>
  <progress
    :value="done"
    :max="total"
    class="block w-auto h-1 overflow-hidden border-0 rounded-full appearance-none bg-n-alpha-2 [&::-webkit-progress-bar]:bg-n-alpha-2 [&::-webkit-progress-value]:rounded-full [&::-webkit-progress-value]:bg-n-brand [&::-webkit-progress-value]:transition-all [&::-webkit-progress-value]:duration-500 [&::-moz-progress-bar]:rounded-full [&::-moz-progress-bar]:bg-n-brand"
  />
</template>
