<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useMessageContext } from './provider.js';
import { MESSAGE_VARIANTS, ORIENTATION } from './constants';

const props = defineProps({
  messageId: { type: Number, required: true },
});

const { t } = useI18n();
const { orientation, variant } = useMessageContext();
const store = useStore();
const { isCloudFeatureEnabled } = useAccount();

const isExpanded = ref(false);

const showSparkle = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_V2)
);

const session = computed(() =>
  store.getters['captainAgentSessions/getSessionByMessageId'](props.messageId)
);
const hasFetched = computed(() =>
  store.getters['captainAgentSessions/hasFetched'](props.messageId)
);
const isLoading = computed(
  () =>
    !hasFetched.value ||
    store.getters['captainAgentSessions/isFetching'](props.messageId)
);

const citations = computed(() => session.value?.citations || []);

const scenarioTitles = computed(() =>
  (session.value?.scenarios || []).reduce((map, scenario) => {
    map[scenario.id] = scenario.title;
    return map;
  }, {})
);

const handoffLabel = agentName => {
  const scenarioId = agentName.match(/^scenario_(\d+)/)?.[1];
  return scenarioTitles.value[scenarioId] || agentName;
};

const formatArguments = args => {
  if (!args || typeof args !== 'object') return '';
  return Object.entries(args)
    .map(([key, value]) => `${key}: ${value}`)
    .join(', ');
};

// Timeline of what Captain did during the run: tool calls (with their
// arguments), scenario/agent handoffs, and a final "replied" step. Message
// bodies and raw tool results are intentionally not echoed here.
const steps = computed(() => {
  const runContext = session.value?.runContext;
  const result = [];
  let currentAgent = null;

  (Array.isArray(runContext) ? runContext : []).forEach(entry => {
    if (entry?.role !== 'assistant') return;

    const agentName = entry.agentName;
    if (agentName && agentName !== currentAgent) {
      if (currentAgent !== null) {
        result.push({
          type: 'handoff',
          label: t('CONVERSATION.CAPTAIN_GENERATION.STEP_HANDOFF', {
            name: handoffLabel(agentName),
          }),
        });
      }
      currentAgent = agentName;
    }

    (entry.toolCalls || []).forEach(call => {
      result.push({
        type: 'tool',
        label: t('CONVERSATION.CAPTAIN_GENERATION.STEP_TOOL', {
          tool: call.name,
        }),
        detail: formatArguments(call.arguments),
      });
    });
  });

  result.push({
    type: 'replied',
    label: t('CONVERSATION.CAPTAIN_GENERATION.STEP_REPLIED'),
  });
  return result;
});

const STEP_ICONS = {
  tool: 'i-ph-wrench',
  handoff: 'i-ph-user-switch',
  replied: 'i-ph-chat-circle-check',
};

// Model and credits are only surfaced in development to aid debugging.
const devDetails = computed(() => {
  if (!import.meta.env.DEV || !session.value) return null;
  const model = t('CONVERSATION.CAPTAIN_GENERATION.MODEL', {
    model: session.value.llmModel,
  });
  const credits = t('CONVERSATION.CAPTAIN_GENERATION.CREDITS', {
    credits: session.value.creditsConsumed,
  });
  return `${model} · ${credits}`;
});

// With the sparkle at the row start, the meta gets pushed to the opposite end;
// without it, fall back to the message orientation.
const rowLayoutClass = computed(() => {
  if (showSparkle.value) return 'justify-between';
  return orientation.value === ORIENTATION.LEFT
    ? 'justify-start'
    : 'justify-end';
});

// Blend the sparkle with the bubble background: amber on private notes,
// slate everywhere else. Tokens adapt to dark mode on their own.
const sparkleColorClass = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.PRIVATE) {
    return isExpanded.value
      ? 'text-n-amber-12/80'
      : 'text-n-amber-12/40 hover:text-n-amber-12/70';
  }
  return isExpanded.value
    ? 'text-n-slate-12'
    : 'text-n-slate-11/60 hover:text-n-slate-12';
});

const prefetch = () => {
  store.dispatch('captainAgentSessions/fetch', props.messageId);
};

const toggle = () => {
  isExpanded.value = !isExpanded.value;
  if (isExpanded.value) prefetch();
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <Transition
      enter-active-class="transition-[opacity,transform] duration-200 ease-out"
      enter-from-class="opacity-0 translate-y-1"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition-[opacity,transform] duration-150 ease-in"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 translate-y-1"
    >
      <div
        v-if="isExpanded"
        class="flex flex-col gap-3 p-3 text-xs rounded-lg bg-n-alpha-black1"
      >
        <span v-if="isLoading">
          {{ t('CONVERSATION.CAPTAIN_GENERATION.LOADING') }}
        </span>
        <span v-else-if="!session">
          {{ t('CONVERSATION.CAPTAIN_GENERATION.EMPTY') }}
        </span>
        <template v-else>
          <div class="flex flex-col gap-1">
            <span class="font-medium opacity-70">
              {{ t('CONVERSATION.CAPTAIN_GENERATION.TIMELINE') }}
            </span>
            <div class="flex flex-col">
              <div
                v-for="(step, index) in steps"
                :key="index"
                class="flex gap-2"
              >
                <div class="flex flex-col items-center">
                  <span
                    class="flex items-center justify-center rounded-full size-5 bg-n-alpha-2 text-n-slate-11"
                  >
                    <Icon :icon="STEP_ICONS[step.type]" class="size-3" />
                  </span>
                  <span
                    v-if="index < steps.length - 1"
                    class="flex-1 w-px min-h-2 bg-n-weak"
                  />
                </div>
                <div class="flex flex-col pb-2 min-w-0">
                  <span>{{ step.label }}</span>
                  <span v-if="step.detail" class="opacity-70 break-words">
                    {{ step.detail }}
                  </span>
                </div>
              </div>
            </div>
          </div>
          <div v-if="citations.length" class="flex flex-col gap-1.5">
            <span class="font-medium opacity-70">
              {{ t('CONVERSATION.CAPTAIN_GENERATION.SOURCES') }}
            </span>
            <p class="m-0 opacity-70">
              {{
                t('CONVERSATION.CAPTAIN_GENERATION.SOURCES_SUMMARY', {
                  count: citations.length,
                })
              }}
            </p>
            <ul class="flex flex-col gap-1 m-0 list-disc ps-4">
              <li v-for="citation in citations" :key="citation.id">
                <a
                  v-if="citation.link"
                  :href="citation.link"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="text-n-blue-11 hover:underline"
                >
                  {{ citation.title || citation.link }}
                </a>
                <span v-else>{{ citation.title }}</span>
              </li>
            </ul>
          </div>
          <span v-if="devDetails" class="opacity-70">{{ devDetails }}</span>
        </template>
      </div>
    </Transition>
    <div class="flex items-center gap-1.5" :class="rowLayoutClass">
      <button
        v-if="showSparkle"
        v-tooltip="t('CONVERSATION.CAPTAIN_GENERATION.TITLE')"
        type="button"
        class="inline-flex items-center gap-1 p-0 bg-transparent border-0 cursor-pointer"
        :class="sparkleColorClass"
        @mouseenter="prefetch"
        @focus="prefetch"
        @click="toggle"
      >
        <Icon icon="i-ph-sparkle-fill" class="size-3.5" />
        <span class="text-xs">
          {{ t('CONVERSATION.CAPTAIN_GENERATION.GENERATED_BY') }}
        </span>
      </button>
      <slot name="meta" />
    </div>
  </div>
</template>
