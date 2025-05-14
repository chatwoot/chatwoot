<script>
export default {
  props: {
    message: { type: String, default: '' },
  },
};
</script>

<template>
  <div class="flex-col p-8 flex items-center justify-center">
    <img
      class="flex w-20 h-20 mb-2"
      src="dashboard/assets/images/not-found.png"
      alt="not-found"
    />
    <p class="flex text-base font-medium text-slate-600 dark:text-slate-400">
      {{ message }}
    </p>
  </div>
</template>
