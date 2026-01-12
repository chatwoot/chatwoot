<script setup>
import { reactive, computed, watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import AgentActivityRow from './AgentActivityRow.vue';
import AgentActivityLegend from './AgentActivityLegend.vue';
import AgentActivityTimeScale from './AgentActivityTimeScale.vue';

const props = defineProps({
  filters: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['timelineChange']);

const { t } = useI18n();

const visibleAgents = useMapGetter(['agentActivity/getVisibleAgentActivity']);

const timeline = reactive({
  start: null,
  end: null,
});

watch(
  () => [props.filters.since, props.filters.until],
  ([since, until]) => {
    if (since && until) {
      timeline.start = since;
      timeline.end = until;
    }
  },
  { immediate: true }
);

const shiftTimeline = direction => {
  const range = timeline.end - timeline.start;
  const offset = range * direction;

  timeline.start += offset;
  timeline.end += offset;

  emit('timelineChange', {
    since: timeline.start,
    until: timeline.end,
  });
};

const MIN_RANGE = 1 * 60 * 1000;
const MAX_RANGE = 10 * 365 * 24 * 60 * 60 * 1000;

const ZOOM_FACTOR = 0.15;

const zoomTimeline = event => {
  if (!event.ctrlKey) return;

  const range = timeline.end - timeline.start;
  const delta = Math.sign(event.deltaY);

  if (delta > 0 && range >= MAX_RANGE) return;

  if (delta < 0 && range <= MIN_RANGE) return;

  const zoomAmount = range * ZOOM_FACTOR * delta;

  let newStart = timeline.start + zoomAmount;
  let newEnd = timeline.end - zoomAmount;

  const newRange = newEnd - newStart;

  if (newRange < MIN_RANGE || newRange > MAX_RANGE) return;

  timeline.start = newStart;
  timeline.end = newEnd;

  emit('timelineChange', {
    since: timeline.start,
    until: timeline.end,
  });
};

const formatDate = ts =>
  new Date(ts).toLocaleDateString('ru', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });

const dateLabel = computed(() => {
  if (!timeline.start || !timeline.end) return '';

  const startDate = formatDate(timeline.start);
  const endDate = formatDate(timeline.end);

  return startDate === endDate
    ? startDate
    : t('AGENT_ACTIVITY_REPORTS.DATE_RANGE', {
        start: startDate,
        end: endDate,
      });
});
</script>

<template>
  <div
    class="flex flex-col gap-4 p-4 bg-n-solid-2 rounded-xl outline outline-1 outline-n-container"
    @wheel.prevent="zoomTimeline"
  >
    <div class="flex justify-between items-center">
      <h3 class="font-medium">
        {{ t('AGENT_ACTIVITY_REPORTS.HEADER') }}
      </h3>

      <div class="flex items-center gap-2">
        <button
          class="px-2 py-1 text-sm rounded bg-n-solid-3 hover:bg-n-solid-4"
          @click="shiftTimeline(-1)"
        >
          {{ t('AGENT_ACTIVITY_REPORTS.PREVIOUS') }}
        </button>

        <button
          class="px-2 py-1 text-sm rounded bg-n-solid-3 hover:bg-n-solid-4"
          @click="shiftTimeline(1)"
        >
          {{ t('AGENT_ACTIVITY_REPORTS.NEXT') }}
        </button>

        <AgentActivityLegend />
      </div>
    </div>

    <div class="ml-48 text-sm font-medium text-n-slate-12">
      {{ dateLabel }}
    </div>

    <AgentActivityTimeScale
      v-if="timeline.start && timeline.end"
      :start="timeline.start"
      :end="timeline.end"
    />

    <div class="flex flex-col gap-4">
      <AgentActivityRow
        v-for="agent in visibleAgents"
        :key="agent.id"
        :agent="agent"
        :start="timeline.start"
        :end="timeline.end"
      />
    </div>

    <div class="text-xs text-n-slate-11 text-center">
      {{ t('AGENT_ACTIVITY_REPORTS.TIMEZONE_DESCRIPTION') }}
    </div>
  </div>
</template>
