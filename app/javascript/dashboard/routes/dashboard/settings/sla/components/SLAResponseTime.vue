<script setup>
defineProps({
  responseType: {
    type: String,
    default: '',
  },
  responseTime: {
    type: String,
    default: '',
  },
});
</script>
<template>
  <div
    class="flex flex-row items-start w-full h-full gap-1 sm:items-end sm:px-6 sm:py-2 sm:gap-2 sm:flex-col"
  >
    <span
      class="inline-flex items-center gap-1 tracking-[-0.6%] text-sm ltr:pl-1.5 sm:ltr:pl-0 rtl:pr-1.5 sm:rtl:pr-0 text-slate-600 dark:text-slate-300"
    >
      <fluent-icon
        v-tooltip.left="$t(`SLA.LIST.RESPONSE_TYPES.${responseType}`)"
        size="14"
        icon="information"
        type="outline"
        class="flex-shrink-0 hidden text-sm font-normal sm:flex sm:font-medium text-slate-500 dark:text-slate-500"
      />
      {{ $t(`SLA.LIST.RESPONSE_TYPES.SHORT_HAND.${responseType}`) }}
      <span class="flex sm:hidden">:</span>
    </span>
    <span
      class="text-sm sm:text-2xl font-medium tracking-[-1.5%] text-slate-900 dark:text-slate-25"
    >
      {{ responseTime }}
    </span>
  </div>
</template>
