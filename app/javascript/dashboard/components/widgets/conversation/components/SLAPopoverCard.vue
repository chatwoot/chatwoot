<script setup>
import SLAEventItem from './SLAEventItem.vue';

const slaMissedEvents = [
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
    id: 79,
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
  {
    id: 74,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
  {
    id: 75,
    event_type: 'nrt',
    meta: {
      message_id: 962,
    },
    updated_at: 1712645713,
    created_at: 1712645713,
  },
];

const nrtMisses = slaMissedEvents.filter(
  slaEvent => slaEvent.event_type === 'nrt'
);
const frtMiss = slaMissedEvents.find(slaEvent => slaEvent.event_type === 'frt');
const rtMiss = slaMissedEvents.find(slaEvent => slaEvent.event_type === 'rt');
</script>
<template>
  <div
    class="absolute flex flex-col items-start bg-[#fdfdfd] dark:bg-slate-800 z-50 p-4 border border-solid border-slate-75 dark:border-slate-700 w-[384px] rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <span class="text-sm font-medium text-slate-900 dark:text-slate-200">
      {{ $t('SLA.EVENTS.TITLE') }}
    </span>

    <SLA-event-item
      v-if="frtMiss"
      :label="$t('SLA.EVENTS.FRT')"
      :created-at="frtMiss.created_at"
    />

    <SLA-event-item
      v-for="(missedSLA, index) in nrtMisses"
      :key="missedSLA.id"
      :label="$t('SLA.EVENTS.NRT')"
      :show-label="index === 0"
      :created-at="frtMiss.created_at"
    />
    <div class="flex flex-col items-end w-full">
      <woot-button
        size="small"
        icon="plus-sign"
        variant="link"
        color-scheme="secondary"
        class="hover:!no-underline hover:!bg-transparent dark:hover:!bg-transparent"
      >
        {{ $t('SLA.EVENTS.SHOW_MORE', { count: nrtMisses.length }) }}
      </woot-button>
    </div>

    <SLA-event-item
      v-if="rtMiss"
      :label="$t('SLA.EVENTS.RT')"
      :created-at="rtMiss.created_at"
    />
  </div>
</template>
