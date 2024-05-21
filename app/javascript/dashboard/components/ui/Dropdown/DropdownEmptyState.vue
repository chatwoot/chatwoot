<script setup>
defineProps({
  message: {
    type: String,
    default: '',
  },
});
</script>
<template>
  <div
    class="flex items-center justify-center h-10 text-sm text-slate-500 dark:text-slate-300"
  >
    {{ message }}
  </div>
</template>
