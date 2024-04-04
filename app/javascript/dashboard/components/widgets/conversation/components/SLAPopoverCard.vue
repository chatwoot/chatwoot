<script setup>
import { format, fromUnixTime } from 'date-fns';

defineProps({
  allMissedSlas: {
    type: Array,
    default: () => [],
  },
});

const formatDate = timestamp => format(fromUnixTime(timestamp), 'PP');

const upperCase = str => str.toUpperCase();
</script>
<template>
  <div
    class="absolute flex flex-col items-start bg-[#fdfdfd] dark:bg-slate-800 z-50 p-4 border border-solid border-slate-75 dark:border-slate-700 w-[384px] rounded-xl gap-4"
  >
    <div
      v-for="missedSLA in allMissedSlas"
      :key="missedSLA.id"
      class="flex items-center justify-between w-full"
    >
      <span
        class="text-sm font-normal tracking-[-0.6%] w-[140px] truncate text-slate-900 dark:text-slate-50"
      >
        {{
          $t(
            `CONVERSATION.HEADER.SLA_POPOVER.${upperCase(missedSLA.event_type)}`
          )
        }}
      </span>
      <span
        class="text-sm font-normal tracking-[-0.6%] text-slate-600 dark:text-slate-200"
      >
        {{ $t('CONVERSATION.HEADER.SLA_POPOVER.MISSED') }}
      </span>
      <span
        class="text-sm font-normal tracking-[-0.6%] text-slate-900 dark:text-slate-50"
      >
        {{ formatDate(missedSLA.created_at) }}
      </span>
    </div>
  </div>
</template>
