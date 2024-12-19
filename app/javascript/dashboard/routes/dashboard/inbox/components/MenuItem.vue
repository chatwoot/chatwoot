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
    class="flex items-center w-full h-8 px-2 py-1 overflow-hidden text-xs font-medium rounded-md cursor-pointer text-n-slate-12 whitespace-nowrap text-ellipsis hover:text-n-blue-text"
  >
    {{ label }}
  </div>
</template>
