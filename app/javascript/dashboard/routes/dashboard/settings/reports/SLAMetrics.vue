<script setup>
// defineProps({
//   keepAlive: {
//     type: Boolean,
//     default: true,
//   },
// });
</script>

<template>
  <div
    class="flex w-full gap-14 bg-white dark:bg-slate-900 rounded-xl border border-slate-75 dark:border-slate-700/50 px-6 py-4 max-h-[92px] h-full"
  >
    <div class="flex flex-col items-start justify-center min-w-[160px] gap-2">
      <span
        class="inline-flex items-center gap-1 tracking-[-0.6%] text-sm text-slate-700 dark:text-slate-200 font-medium"
      >
        Hit rate
        <fluent-icon
          v-tooltip.right="`Hit rate`"
          size="14"
          icon="information"
          type="outline"
          class="flex-shrink-0 hidden text-sm font-normal sm:flex sm:font-medium text-slate-500 dark:text-slate-500"
        />
      </span>
      <span
        class="text-2xl font-medium text-slate-900 dark:text-slate-25 tracking-[-1.5%]"
      >
        12%
      </span>
    </div>
    <div class="border border-slate-75 dark:border-slate-700/50 h-full w-px" />
    <div class="flex flex-col gap-2 items-start justify-center min-w-[160px]">
      <span
        class="inline-flex items-center gap-1 tracking-[-0.6%] text-sm text-slate-700 dark:text-slate-200 font-medium"
      >
        No. of breaches
        <fluent-icon
          v-tooltip.right="`No of breaches`"
          size="14"
          icon="information"
          type="outline"
          class="flex-shrink-0 hidden text-sm font-normal sm:flex sm:font-medium text-slate-500 dark:text-slate-500"
        />
      </span>
      <span
        class="text-2xl font-medium text-slate-900 dark:text-slate-25 tracking-[-1.5%]"
      >
        5
      </span>
    </div>
  </div>
</template>
