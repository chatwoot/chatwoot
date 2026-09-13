<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import ActivityEventDetail from './ActivityEventDetail.vue';
import ExecutionGraph from './ExecutionGraph.vue';

const props = defineProps({
  events: { type: Array, default: () => [] },
  emptyMessage: { type: String, default: '' },
});
const GRAPH_KINDS = [
  'program',
  'query_request',
  'query',
  'result',
  'action',
  'error',
  'reason',
  'reason_result',
];
const { t } = useI18n();
const kinds = computed(() => ({
  discovery: {
    label: t('CAPTAIN_ASK.KINDS.discovery'),
    icon: 'i-lucide-search',
  },
  description: {
    label: t('CAPTAIN_ASK.KINDS.description'),
    icon: 'i-lucide-book-open',
  },
  program: { label: t('CAPTAIN_ASK.KINDS.program'), icon: 'i-lucide-code-xml' },
  query_request: {
    label: t('CAPTAIN_ASK.KINDS.query_request'),
    icon: 'i-lucide-sparkles',
  },
  query: { label: t('CAPTAIN_ASK.KINDS.query'), icon: 'i-lucide-database' },
  result: { label: t('CAPTAIN_ASK.KINDS.result'), icon: 'i-lucide-check' },
  action: { label: t('CAPTAIN_ASK.KINDS.action'), icon: 'i-lucide-zap' },
  error: { label: t('CAPTAIN_ASK.KINDS.error'), icon: 'i-lucide-circle-alert' },
  reason: { label: t('CAPTAIN_ASK.KINDS.reason'), icon: 'i-lucide-brain' },
  reason_result: {
    label: t('CAPTAIN_ASK.KINDS.reason_result'),
    icon: 'i-lucide-check',
  },
}));
const failed = event =>
  event.kind === 'error' || event.data.status === 'failed';
const subtitle = event => {
  if (event.kind === 'discovery')
    return event.data.query || t('CAPTAIN_ASK.TRACE.ALL_CAPABILITIES');
  if (event.kind === 'description') return event.data.name;
  if (['query_request', 'reason'].includes(event.kind))
    return event.data.instruction;
  if (event.kind === 'query')
    return t('CAPTAIN_ASK.TRACE.QUERY_OFFSET', { offset: event.data.offset });
  if (event.kind === 'program')
    return t('CAPTAIN_ASK.TRACE.LINES', {
      count: event.data.source.split('\n').length,
    });
  if (event.kind === 'action') return event.data.operation;
  if (event.kind === 'error') return event.data.message;
  return t('CAPTAIN_ASK.TRACE.OUTPUT');
};
const graphNodes = computed(() =>
  props.events.flatMap((event, index) => {
    if (!GRAPH_KINDS.includes(event.kind)) return [];
    let status = 'step';
    if (
      ['result', 'reason_result'].includes(event.kind) ||
      event.data.status === 'completed'
    ) {
      status = 'success';
    }
    if (failed(event)) status = 'error';
    return [
      {
        ...kinds.value[event.kind],
        index,
        event,
        kind: event.kind,
        reasonId: event.data.reason_id,
        isQueryResult:
          event.kind === 'result' &&
          Boolean(event.data.value?.result_ref && event.data.value?.source),
        depth: event.depth,
        detail: subtitle(event),
        status,
      },
    ];
  })
);
</script>

<template>
  <aside
    class="lg:w-[28rem] shrink-0 min-w-0 max-h-[28rem] lg:max-h-none overflow-y-auto border-t lg:border-t-0 lg:border-s border-n-weak bg-n-solid-1"
  >
    <header
      class="sticky top-0 z-10 flex items-center justify-between px-5 py-4 bg-n-solid-1 border-b border-n-weak"
    >
      <h2 class="m-0 text-heading-3 text-n-slate-12">
        {{ t('CAPTAIN_ASK.ACTIVITY') }}
      </h2>
      <span class="text-xs tabular-nums text-n-slate-10">{{
        t('CAPTAIN_ASK.TRACE.STEPS', { count: events.length })
      }}</span>
    </header>
    <div
      v-if="!events.length"
      class="flex flex-col items-center gap-3 px-6 py-12 text-center text-n-slate-10"
    >
      <Icon icon="i-lucide-list-tree" class="size-6" />
      <p class="m-0 text-sm">
        {{ emptyMessage || t('CAPTAIN_ASK.NO_ACTIVITY') }}
      </p>
    </div>
    <div class="divide-y divide-n-weak">
      <Accordion
        v-if="graphNodes.length"
        :title="t('CAPTAIN_ASK.TRACE.GRAPH')"
        is-open
        class="!border-0 !rounded-none"
      >
        <ExecutionGraph :nodes="graphNodes" />
      </Accordion>
      <div v-for="(event, index) in events" :key="index" class="scroll-mt-20">
        <Accordion
          :title="kinds[event.kind].label"
          class="!border-0 !rounded-none"
        >
          <template #title>
            <span class="flex flex-1 items-center gap-3 min-w-0">
              <Icon
                :icon="kinds[event.kind].icon"
                class="size-4 shrink-0"
                :class="failed(event) ? 'text-n-ruby-11' : 'text-n-slate-10'"
              />
              <span class="flex-1 min-w-0 text-start">
                <span
                  class="block text-sm font-medium"
                  :class="failed(event) ? 'text-n-ruby-11' : 'text-n-slate-12'"
                >
                  {{ kinds[event.kind].label }}
                </span>
                <span class="block truncate text-xs text-n-slate-10 mt-0.5">{{
                  subtitle(event)
                }}</span>
              </span>
              <span class="text-xs tabular-nums text-n-slate-9">{{
                index + 1
              }}</span>
            </span>
          </template>
          <ActivityEventDetail :event="event" />
        </Accordion>
      </div>
    </div>
  </aside>
</template>
