<script setup>
defineProps({
  message: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="custom-dashed-border p-4 rounded-xl">
    <p class="text-center text-n-slate-10 text-body-main">{{ message }}</p>
  </div>
</template>
