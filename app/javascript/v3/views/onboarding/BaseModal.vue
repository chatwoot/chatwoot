<script setup>
import { defineProps } from 'vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    id="modal-body"
    class="dark:shadow-[#000] rounded-2xl p-8 border shadow border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 z-10 relative w-full max-w-[560px]"
  >
    <h2
      class="font-bold text-[28px] leading-8 tracking-[2%] text-slate-900 dark:text-white"
    >
      <slot name="title">{{ title }}</slot>
    </h2>
    <p
      class="text-base text-slate-600 leading-6 tracking-[-1.1%] mt-2 dark:text-slate-200"
    >
      <slot name="subtitle">{{ subtitle }}</slot>
    </p>
    <div class="mt-8 space-y-5">
      <slot />
    </div>
  </div>
</template>
