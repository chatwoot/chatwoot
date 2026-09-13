<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SchemeCode from './SchemeCode.vue';
import WootqlCode from './WootqlCode.vue';
import ActivityValue from './ActivityValue.vue';
import CapabilityDetail from './CapabilityDetail.vue';

defineProps({ events: { type: Array, default: () => [] } });
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
}));
const failed = event =>
  event.kind === 'error' || event.data.status === 'failed';
const subtitle = event => {
  if (event.kind === 'discovery')
    return event.data.query || t('CAPTAIN_ASK.TRACE.ALL_CAPABILITIES');
  if (event.kind === 'description') return event.data.name;
  if (event.kind === 'query_request') return event.data.instruction;
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
      <p class="m-0 text-sm">{{ t('CAPTAIN_ASK.NO_ACTIVITY') }}</p>
    </div>
    <div class="divide-y divide-n-weak">
      <Accordion
        v-for="(event, index) in events"
        :key="index"
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
        <div class="min-w-0 pt-1 pb-2 space-y-4">
          <template v-if="event.kind === 'discovery'">
            <p class="m-0 text-xs text-n-slate-10">
              {{
                t('CAPTAIN_ASK.TRACE.MATCHES', {
                  count: Object.keys(event.data.matches).length,
                })
              }}
            </p>
            <div class="divide-y divide-n-weak">
              <Accordion
                v-for="(contract, name) in event.data.matches"
                :key="name"
                :title="name"
                class="!border-0 !rounded-none"
              >
                <CapabilityDetail :name="name" :contract="contract" />
              </Accordion>
            </div>
          </template>
          <CapabilityDetail
            v-else-if="event.kind === 'description'"
            :name="event.data.name"
            :contract="event.data.contract"
          />
          <SchemeCode
            v-else-if="event.kind === 'program'"
            :source="event.data.source"
          />
          <WootqlCode
            v-else-if="event.kind === 'query'"
            :source="event.data.source"
          />
          <p
            v-else-if="event.kind === 'query_request'"
            class="m-0 whitespace-pre-wrap break-words text-sm text-n-slate-12"
          >
            {{ event.data.instruction }}
          </p>
          <ActivityValue
            v-else-if="event.kind === 'result'"
            :value="event.data.value"
          />
          <div
            v-else-if="event.kind === 'error'"
            class="border-s-2 border-n-ruby-7 ps-3"
          >
            <p
              class="m-0 text-sm text-n-ruby-11 whitespace-pre-wrap break-words"
            >
              {{ event.data.message }}
            </p>
          </div>
          <template v-else-if="event.kind === 'action'">
            <div class="flex items-center gap-2 text-sm">
              <span
                class="size-1.5 rounded-full"
                :class="failed(event) ? 'bg-n-ruby-9' : 'bg-n-teal-9'"
              />
              <span class="text-n-slate-12">{{
                failed(event)
                  ? t('CAPTAIN_ASK.TRACE.FAILED')
                  : t('CAPTAIN_ASK.TRACE.COMPLETED')
              }}</span>
              <span class="ms-auto font-mono text-xs text-n-slate-10">
                {{
                  t('CAPTAIN_ASK.TRACE.RECORD', {
                    type: event.data.target?.type,
                    id: event.data.target?.id,
                  })
                }}
              </span>
            </div>
            <p
              v-if="event.data.error"
              class="m-0 text-sm text-n-ruby-11 break-words"
            >
              {{ event.data.error }}
            </p>
            <ActivityValue
              v-if="event.data.result"
              :value="event.data.result"
            />
          </template>
          <p v-if="event.depth" class="m-0 text-xs text-n-slate-9">
            {{ t('CAPTAIN_ASK.TRACE.WORKER_DEPTH', { depth: event.depth }) }}
          </p>
        </div>
      </Accordion>
    </div>
  </aside>
</template>
