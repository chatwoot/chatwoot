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
    class="flex items-center w-full h-8 px-2 py-1 overflow-hidden text-xs font-medium rounded-md cursor-pointer text-slate-800 dark:text-slate-100 whitespace-nowrap text-ellipsis hover:text-woot-600 dark:hover:text-woot-500"
  >
    {{ label }}
  </div>
</template>
