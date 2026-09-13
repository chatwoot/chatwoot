<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import SchemeCode from './SchemeCode.vue';
import WootqlCode from './WootqlCode.vue';
import ActivityValue from './ActivityValue.vue';
import CapabilityDetail from './CapabilityDetail.vue';

const props = defineProps({ event: { type: Object, required: true } });
const { t } = useI18n();
const failed = computed(
  () => props.event.kind === 'error' || props.event.data.status === 'failed'
);
</script>

<template>
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
    <template v-else-if="event.kind === 'reason'">
      <p class="m-0 whitespace-pre-wrap break-words text-sm text-n-slate-12">
        {{ event.data.instruction }}
      </p>
      <h4 class="m-0 text-sm font-medium text-n-slate-11">
        {{ t('CAPTAIN_ASK.TRACE.REASON_INPUT') }}
      </h4>
      <ActivityValue :value="event.data.input" />
      <h4 class="m-0 text-sm font-medium text-n-slate-11">
        {{ t('CAPTAIN_ASK.TRACE.REASON_SCHEMA') }}
      </h4>
      <ActivityValue :value="event.data.schema" />
    </template>
    <ActivityValue
      v-else-if="['result', 'reason_result'].includes(event.kind)"
      :value="event.data.value"
    />
    <div
      v-else-if="event.kind === 'error'"
      class="border-s-2 border-n-ruby-7 ps-3"
    >
      <p class="m-0 text-sm text-n-ruby-11 whitespace-pre-wrap break-words">
        {{ event.data.message }}
      </p>
    </div>
    <template v-else-if="event.kind === 'action'">
      <div class="flex items-center gap-2 text-sm">
        <span
          class="size-1.5 rounded-full"
          :class="failed ? 'bg-n-ruby-9' : 'bg-n-teal-9'"
        />
        <span class="text-n-slate-12">{{
          failed
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
      <p v-if="event.data.error" class="m-0 text-sm text-n-ruby-11 break-words">
        {{ event.data.error }}
      </p>
      <ActivityValue v-if="event.data.result" :value="event.data.result" />
    </template>
    <p v-if="event.depth" class="m-0 text-xs text-n-slate-9">
      {{ t('CAPTAIN_ASK.TRACE.WORKER_DEPTH', { depth: event.depth }) }}
    </p>
  </div>
</template>
