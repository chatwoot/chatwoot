<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
  },
};
</script>

<template>
  <div class="relative my-4 section-separator">
    <div class="absolute inset-0 flex items-center" aria-hidden="true">
      <div class="w-full border-t border-n-strong" />
    </div>
    <div v-if="label" class="relative flex justify-center text-sm">
      <span class="bg-white dark:bg-n-solid-2 px-2 text-n-slate-10">
        {{ label }}
      </span>
    </div>
  </div>
</template>
