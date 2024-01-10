<template>
  <div class="flex items-center justify-center p-8">
    <h6
      class="block text-base text-center w-100 text-slate-800 dark:text-slate-300"
    >
      <span class="mr-3">{{ message }}</span>
      <span class="spinner" />
    </h6>
  </div>
</template>
<script>
export default {
  props: {
    message: { type: String, default: '' },
  },
};
</script>
