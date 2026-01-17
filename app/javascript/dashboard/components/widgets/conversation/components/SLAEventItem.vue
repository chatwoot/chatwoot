<script setup>
import { format, fromUnixTime, intervalToDuration } from 'date-fns';
import { computed } from 'vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  items: {
    type: Array,
    required: true,
  },
  conversationCreatedAt: {
    type: Number,
    default: null,
  },
  slaThreshold: {
    type: Number,
    default: null,
  },
});

const formatDate = timestamp =>
  format(fromUnixTime(timestamp), 'MMM dd, yyyy, HH:mm');

const formatDuration = (seconds) => {
  if (!seconds || seconds < 0) return '--';
  
  const duration = intervalToDuration({ start: 0, end: seconds * 1000 });
  const parts = [];
  
  if (duration.days) parts.push(`${duration.days}d`);
  if (duration.hours) parts.push(`${duration.hours}h`);
  if (duration.minutes) parts.push(`${duration.minutes}m`);
  if (!parts.length && duration.seconds) parts.push(`${duration.seconds}s`);
  
  return parts.join(' ') || '0s';
};

const formatSlaThreshold = computed(() => {
  return props.slaThreshold ? formatDuration(props.slaThreshold) : '--';
});

const calculateRealTime = (eventCreatedAt) => {
  if (!props.conversationCreatedAt || !eventCreatedAt) return '--';
  const diff = eventCreatedAt - props.conversationCreatedAt;
  return diff >= 0 ? formatDuration(diff) : '--';
};

const calculateDifference = (eventCreatedAt) => {
  if (!props.conversationCreatedAt || !eventCreatedAt || !props.slaThreshold) return { value: '--', isNegative: false };
  
  const realTime = eventCreatedAt - props.conversationCreatedAt;
  const diff = realTime - props.slaThreshold;
  
  if (diff < 0) {
    return { value: '--', isNegative: false };
  }
  
  return { value: formatDuration(Math.abs(diff)), isNegative: diff < 0 };
};
</script>

<template>
  <div class="flex flex-col w-full gap-4 border-b border-n-weak pb-4 last:border-b-0 last:pb-0">
    <div class="flex items-start gap-4">
      <span
        class="text-sm font-medium text-n-slate-12 min-w-[160px] flex-shrink-0"
      >
        {{ label }}
      </span>
      <div class="flex-1 min-w-0">
        <div class="grid grid-cols-4 gap-2 mb-2 text-xs font-medium text-n-slate-11">
          <div>INÍCIO DO SLA</div>
          <div class="text-center">SLA</div>
          <div class="text-center">REAL</div>
          <div class="text-center">DIFERENÇA</div>
        </div>
        <div
          v-for="item in items"
          :key="item.id"
          class="grid grid-cols-4 gap-2 py-2 text-sm tabular-nums"
        >
          <div class="text-n-slate-12 truncate" :title="formatDate(item.created_at)">
            {{ formatDate(item.created_at) }}
          </div>
          <div class="text-center text-n-slate-11">
            {{ formatSlaThreshold }}
          </div>
          <div class="text-center font-medium" :class="calculateDifference(item.created_at).isNegative ? 'text-green-600' : 'text-amber-600'">
            {{ calculateRealTime(item.created_at) }}
          </div>
          <div class="text-center font-medium text-red-600">
            {{ calculateDifference(item.created_at).value }}
          </div>
        </div>
        <slot name="showMore" />
      </div>
    </div>
  </div>
</template>
