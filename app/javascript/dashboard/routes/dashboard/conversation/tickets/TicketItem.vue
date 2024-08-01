<template>
  <div
    class="w-full text-slate-800 dark:text-slate-100 h-full border-b border-solid border-slate-50 dark:border-slate-800"
  >
    <span
      class="text-base font-medium leading-6 text-slate-800 dark:text-slate-100 h-full"
      >{{ ticket.title }}
    </span>
    <span class="text-slate-600 dark:text-slate-300 text-sm">
      {{ ticket.description }}
    </span>
  </div>
</template>

<script>
export default {
  props: {
    ticket: {
      type: Object,
      required: true,
    },
  },
};
</script>
