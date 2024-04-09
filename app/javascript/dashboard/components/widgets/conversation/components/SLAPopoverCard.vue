<script setup>
import SLAEventItem from './SLAEventItem.vue';

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
    id: 70,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 71,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 72,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 73,
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

    <SLA-event-item
      v-if="frtMiss"
      label="FRT Misses"
      :created-at="frtMiss.created_at"
    />

    <SLA-event-item
      v-for="(missedSLA, index) in nrtMisses"
      :key="missedSLA.id"
      label="NRT Misses"
      :show-label="index === 0"
      :created-at="frtMiss.created_at"
    />

    <SLA-event-item
      v-if="rtMiss"
      label="RT Misses"
      :created-at="rtMiss.created_at"
    />
  </div>
</template>
