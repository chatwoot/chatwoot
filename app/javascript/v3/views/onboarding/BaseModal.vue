<script>
export default {
  name: 'OnboardingBaseModal',
  props: {
    title: {
      type: String,
      required: true,
    },
    subtitle: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div
    id="modal-body"
    class="dark:shadow-[#000] rounded-3xl p-10 pt-14 border shadow border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 z-10 relative w-full max-w-[560px]"
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
    <div class="mt-3">
      <slot />
    </div>
  </div>
</template>
