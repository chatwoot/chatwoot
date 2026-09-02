<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  runDetails: { type: Object, required: true },
  setupSummary: { type: Object, required: true },
});

const { t } = useI18n();
const formattedArguments = argumentsValue =>
  JSON.stringify(argumentsValue || {}, null, 2);

const runSummary = computed(() =>
  t('CAPTAIN.PLAYGROUND.RUN_DETAILS.SUMMARY', {
    duration: props.runDetails.duration_ms,
  })
);
</script>

<template>
  <details class="mt-3 border-t border-n-weak pt-2 text-xs text-n-slate-11">
    <summary class="cursor-pointer font-medium text-n-slate-12">
      {{ runSummary }}
    </summary>
    <div class="mt-3 flex flex-col gap-3">
      <div class="grid grid-cols-2 gap-2">
        <span>
          {{
            t('CAPTAIN.PLAYGROUND.RUN_DETAILS.HANDLER_VALUE', {
              handler: runDetails.handler?.title,
            })
          }}
          <span
            v-if="runDetails.handler?.temporary"
            class="ms-1 rounded bg-n-iris-3 px-1 py-0.5"
          >
            {{ t('CAPTAIN.PLAYGROUND.SETUP.TEMPORARY') }}
          </span>
        </span>
        <span>
          {{
            t(
              'CAPTAIN.PLAYGROUND.RUN_DETAILS.SCENARIOS',
              setupSummary.scenarioCount
            )
          }}
        </span>
        <span>
          {{
            t('CAPTAIN.PLAYGROUND.RUN_DETAILS.RULES', {
              count: setupSummary.guidelineCount + setupSummary.guardrailCount,
            })
          }}
        </span>
      </div>
      <p v-if="runDetails.temporary_knowledge_attached">
        {{ t('CAPTAIN.PLAYGROUND.RUN_DETAILS.KNOWLEDGE_ATTACHED') }}
      </p>
      <ol v-if="runDetails.events?.length" class="flex flex-col gap-2">
        <li
          v-for="(event, index) in runDetails.events"
          :key="`${event.type}-${index}`"
          class="rounded-lg bg-n-alpha-2 p-2"
        >
          <template v-if="event.type === 'tool'">
            <div class="flex items-center justify-between gap-2">
              <span class="font-medium text-n-slate-12">{{ event.name }}</span>
              <span>{{ event.status }}</span>
            </div>
            <pre class="mt-2 whitespace-pre-wrap break-all font-mono">{{
              formattedArguments(event.arguments)
            }}</pre>
            <p v-if="event.result_preview" class="mt-2 break-words">
              {{ event.result_preview }}
            </p>
          </template>
          <template v-else>
            {{
              t('CAPTAIN.PLAYGROUND.RUN_DETAILS.HANDOFF', {
                from: event.from?.title,
                to: event.to?.title,
              })
            }}
          </template>
        </li>
      </ol>
      <p v-else>{{ t('CAPTAIN.PLAYGROUND.RUN_DETAILS.NO_EVENTS') }}</p>
    </div>
  </details>
</template>
