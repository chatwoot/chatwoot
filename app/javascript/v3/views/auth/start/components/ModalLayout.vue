<template>
  <section
    class="min-h-screen px-8 py-24 dark:text-white bg-woot-25 dark:bg-slate-900"
  >
    <div
      class="max-w-lg rounded-md dark:shadow-[#000] p-8 mx-auto border shadow border-slate-300 dark:border-slate-800 bg-white dark:bg-slate-900"
    >
      <h2 class="text-lg font-bold tracking-tight">
        <slot name="title">
          {{ title }}
        </slot>
      </h2>
      <p class="mt-2 text-sm dark:text-slate-200">
        <slot name="body">
          {{ body }}
        </slot>
      </p>
      <div class="mt-8">
        <slot />
      </div>
    </div>
  </section>
</template>

<script>
export default {
  props: {
    title: {
      type: String,
      default: '',
    },
    body: {
      type: String,
      default: '',
    },
  },
};
</script>
