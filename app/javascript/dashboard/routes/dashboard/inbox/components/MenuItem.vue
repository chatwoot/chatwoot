<script setup>
defineProps({
  label: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    role="button"
    class="flex items-center w-full h-8 px-2 py-1 rounded-md cursor-pointer hover:text-n-blue-text min-w-0"
  >
    <span class="text-xs font-medium truncate text-n-slate-12">
      {{ label }}
    </span>
  </div>
</template>
