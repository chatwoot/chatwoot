<script setup>
defineProps({
  title: {
    type: String,
    default: null,
  },
});
</script>

<template>
  <div
    class="flex-grow-0 flex-shrink-0 w-full h-full max-w-full bg-white border border-transparent border-solid dark:bg-slate-900 dark:border-transparent md:max-w-2xl"
  >
    <h3
      v-if="$slots.title || title"
      class="text-lg text-black-900 dark:text-slate-200"
    >
      <slot name="title">{{ title }}</slot>
    </h3>
    <div
      class="mx-0 my-4 border-b border-solid border-slate-25 dark:border-slate-800"
    >
      <slot />
    </div>
    <div class="flex justify-between">
      <div>
        <slot name="footer-left" />
      </div>
      <div>
        <slot name="footer-right" />
      </div>
    </div>
  </div>
</template>
