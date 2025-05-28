<script>
export default {
  props: {
    message: { type: String, default: '' },
  },
};
</script>

<template>
  <div class="flex items-center justify-center p-8">
    <h6
      class="flex items-center gap-2 text-base text-center w-100 text-slate-800 dark:text-slate-300"
    >
      <span class="text-base font-medium text-slate-800 dark:text-slate-100">
        {{ message }}
      </span>
      <span class="spinner" />
    </h6>
  </div>
</template>
