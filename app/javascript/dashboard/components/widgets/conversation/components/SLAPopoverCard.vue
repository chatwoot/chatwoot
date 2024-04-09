<script setup>
import { format, fromUnixTime } from 'date-fns';

const allMissedSlas = [
  {
    id: 64,
    event_type: 'frt',
    meta: {},
    updated_at: 1712644234,
    created_at: 1712644234,
  },
  {
    id: 66,
    event_type: 'rt',
    meta: {},
    updated_at: 1712644234,
    created_at: 1712644234,
  },
  {
    id: 67,
    event_type: 'nrt',
    meta: {
      message_id: 956,
    },
    updated_at: 1712644502,
    created_at: 1712644502,
  },
  {
    id: 68,
    event_type: 'nrt',
    meta: {
      message_id: 958,
    },
    updated_at: 1712644817,
    created_at: 1712644817,
  },
  {
    id: 69,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 69,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 69,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 69,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 69,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 69,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 69,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
];

const nrtMisses = allMissedSlas.filter(
  missedSLA => missedSLA.event_type === 'nrt'
);

const frtMiss = allMissedSlas.find(missedSLA => missedSLA.event_type === 'frt');

const rtMiss = allMissedSlas.find(missedSLA => missedSLA.event_type === 'rt');

const formatDate = timestamp =>
  format(fromUnixTime(timestamp), 'MMM dd, yyyy, hh:mm a');
</script>
<template>
  <div
    class="absolute flex flex-col items-start bg-[#fdfdfd] dark:bg-slate-800 z-50 p-4 border border-solid border-slate-75 dark:border-slate-700 w-[384px] rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <span
      class="text-sm font-medium text-slate-900 dark:text-slate-200 sticky top-0"
    >
      SLA Misses
    </span>

    <div v-if="frtMiss" class="flex items-center justify-between w-full">
      <span
        class="text-sm font-normal tracking-[-0.6%] w-[140px] truncate text-slate-500 dark:text-slate-50"
      >
        FRT Misses
      </span>
      <span
        class="text-sm font-normal tracking-[-0.6%] text-slate-900 dark:text-slate-50"
      >
        {{ formatDate(frtMiss.created_at) }}
      </span>
    </div>
    <div
      v-for="(missedSLA, index) in nrtMisses"
      :key="missedSLA.id"
      class="flex items-center justify-between w-full"
    >
      <div class="w-1/2">
        <span
          v-if="index === 0"
          class="text-sm font-normal tracking-[-0.6%] w-[140px] truncate text-slate-500 dark:text-slate-50"
        >
          NRT Misses
        </span>
      </div>
      <div class="w-1/2 text-right">
        <span
          class="text-sm font-normal tracking-[-0.6%] text-slate-900 dark:text-slate-50"
        >
          {{ formatDate(missedSLA.created_at) }}
        </span>
      </div>
    </div>

    <div v-if="rtMiss" class="flex items-center justify-between w-full">
      <span
        class="text-sm font-normal tracking-[-0.6%] w-[140px] truncate text-slate-500 dark:text-slate-50"
      >
        RT Misses
      </span>
      <span
        class="text-sm font-normal tracking-[-0.6%] text-slate-900 dark:text-slate-50"
      >
        {{ formatDate(rtMiss.created_at) }}
      </span>
    </div>
  </div>
</template>
