<script setup>
defineProps({
  hasBusinessHours: {
    type: Boolean,
    required: true,
  },
});
</script>
<template>
  <div
    class="inline-flex items-center min-w-0 gap-1 px-1.5 sm:px-2 py-1 border border-solid rounded-lg border-slate-75 dark:border-slate-700/50"
  >
    <fluent-icon
      size="14"
      :icon="hasBusinessHours ? 'alarm-on' : 'alarm-off'"
      type="outline"
      class="flex-shrink-0"
      :class="
        hasBusinessHours
          ? 'text-slate-600 dark:text-slate-400'
          : 'text-slate-300 dark:text-slate-700'
      "
    />
    <span
      class="hidden text-xs tracking-[0.2%] font-normal truncate sm:block"
      :class="
        hasBusinessHours
          ? 'text-slate-600 dark:text-slate-400'
          : 'text-slate-300 dark:text-slate-700'
      "
    >
      {{
        hasBusinessHours
          ? $t('SLA.LIST.BUSINESS_HOURS_ON')
          : $t('SLA.LIST.BUSINESS_HOURS_OFF')
      }}
    </span>
  </div>
</template>
