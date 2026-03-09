<script setup>
import SLAListItem from './SLAListItem.vue';
</script>

<template>
  <div class="w-full min-h-[12rem] relative">
    <div class="w-full space-y-3">
      <SLAListItem
        class="opacity-25 dark:opacity-20"
        :sla-name="$t('SLA.LIST.EMPTY.TITLE_1')"
        :description="$t('SLA.LIST.EMPTY.DESC_1')"
        first-response="20m"
        next-response="1h"
        resolution-time="24h"
        has-business-hours
      />
      <SLAListItem
        class="opacity-25 dark:opacity-20"
        :sla-name="$t('SLA.LIST.EMPTY.TITLE_2')"
        :description="$t('SLA.LIST.EMPTY.DESC_2')"
        first-response="2h"
        next-response="4h"
        resolution-time="4d"
        has-business-hours
      />
    </div>
    <div
      class="absolute inset-0 flex flex-col items-center justify-center w-full h-full bg-gradient-to-t from-white dark:from-slate-900 to-transparent"
    >
      <slot />
    </div>
  </div>
</template>
