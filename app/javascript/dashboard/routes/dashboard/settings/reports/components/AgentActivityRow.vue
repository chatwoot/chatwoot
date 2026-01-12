<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
  start: {
    type: Number,
    required: true,
  },
  end: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();

const STATUS_COLORS = {
  online: 'bg-green-500',
  busy: 'bg-yellow-500',
  offline: 'bg-gray-300',
};

const visibleIntervals = computed(() => {
  if (!props.agent?.timeline || !Array.isArray(props.agent.timeline)) {
    return [];
  }

  return props.agent.timeline
    .map(item => ({
      status: item.status,
      since: new Date(item.started_at).getTime(),
      until: new Date(item.ended_at).getTime(),
    }))
    .filter(i => i.until > props.start && i.since < props.end)
    .map(i => ({
      ...i,
      since: Math.max(i.since, props.start),
      until: Math.min(i.until, props.end),
    }));
});

const timeToPercent = time => {
  const range = props.end - props.start;
  if (range === 0) return 0;
  return ((time - props.start) / range) * 100;
};

const formatDuration = seconds => {
  if (!seconds) return '0min';

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);

  if (hours > 0) {
    return minutes > 0 ? `${hours}h ${minutes}min` : `${hours}h`;
  }
  return `${minutes}min`;
};

const summary = computed(() => ({
  online: formatDuration(props.agent.online_duration),
  busy: formatDuration(props.agent.busy_duration),
  offline: formatDuration(props.agent.offline_duration),
}));
</script>

<template>
  <div class="flex gap-4 items-start">
    <div class="w-48 flex items-center gap-3">
      <img
        v-if="agent.avatar_url"
        :src="agent.avatar_url"
        :alt="agent.name"
        class="w-8 h-8 rounded-full bg-n-solid-3"
        @error="$event.target.style.display = 'none'"
      />
      <div
        v-else
        class="w-8 h-8 rounded-full bg-n-solid-3 flex items-center justify-center text-sm font-medium"
      >
        {{ agent.name.charAt(0).toUpperCase() }}
      </div>

      <div class="min-w-0">
        <div class="text-sm font-medium truncate">
          {{ agent.name }}
        </div>
        <div class="text-xs text-n-slate-11 truncate">
          {{ agent.email }}
        </div>
      </div>
    </div>

    <div class="flex-1">
      <div class="relative h-4 bg-n-solid-3 rounded overflow-hidden">
        <div
          v-for="(interval, index) in visibleIntervals"
          :key="index"
          class="absolute top-0 h-full transition-all"
          :class="STATUS_COLORS[interval.status] || 'bg-gray-400'"
          :style="{
            left: timeToPercent(interval.since) + '%',
            width:
              timeToPercent(interval.until) -
              timeToPercent(interval.since) +
              '%',
          }"
          :title="`${interval.status}: ${new Date(interval.since).toLocaleTimeString()} - ${new Date(interval.until).toLocaleTimeString()}`"
        />
      </div>

      <div class="flex gap-4 text-xs text-n-slate-11 mt-1">
        <span v-if="agent.online_duration > 0" class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-green-500" />
          {{
            t('AGENT_ACTIVITY_REPORTS.STATUS_WITH_DURATION', {
              status: t('AGENT_ACTIVITY_REPORTS.ONLINE'),
              duration: summary.online,
            })
          }}
        </span>
        <span v-if="agent.busy_duration > 0" class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-yellow-500" />
          {{
            t('AGENT_ACTIVITY_REPORTS.STATUS_WITH_DURATION', {
              status: t('AGENT_ACTIVITY_REPORTS.BUSY'),
              duration: summary.busy,
            })
          }}
        </span>
        <span v-if="agent.offline_duration > 0" class="flex items-center gap-1">
          <span class="w-2 h-2 rounded-full bg-gray-300" />
          {{
            t('AGENT_ACTIVITY_REPORTS.STATUS_WITH_DURATION', {
              status: t('AGENT_ACTIVITY_REPORTS.OFFLINE'),
              duration: summary.offline,
            })
          }}
        </span>
      </div>
    </div>
  </div>
</template>
