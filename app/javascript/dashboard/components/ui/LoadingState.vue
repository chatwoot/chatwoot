<template>
  <p
    class="flex items-center justify-center text-center p-normal gap-2 p-2 text-slate-600 dark:text-slate-400"
  >
    <woot-spinner />
    <span>{{ message }}</span>
  </p>
</template>
<script>
export default {
  props: {
    message: { type: String, default: '' },
  },
};
</script>
