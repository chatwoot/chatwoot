<script setup>
import { computed, ref } from 'vue';
import { useI18n, I18nT } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useMessageContext } from './provider.js';
import { MESSAGE_VARIANTS, ORIENTATION } from './constants';

const props = defineProps({
  messageId: { type: Number, required: true },
});

const { t } = useI18n();
const { orientation, variant, createdAt } = useMessageContext();
const store = useStore();
const { isCloudFeatureEnabled } = useAccount();

const isOpen = ref(false);

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

// Fallback for agents without a matching scenario title:
// "chatwoot_assistant" → "Chatwoot assistant",
// "scenario_5_chatwoot_uptime_agent" → "Chatwoot uptime".
const humanizeAgentName = agentName => {
  const label = agentName
    .replace(/^scenario_\d+_/, '')
    .replace(/_agent$/, '')
    .replaceAll('_', ' ')
    .trim();
  return label.charAt(0).toUpperCase() + label.slice(1);
};

const handoffLabel = agentName => {
  const scenarioId = agentName.match(/^scenario_(\d+)/)?.[1];
  return scenarioTitles.value[scenarioId] || humanizeAgentName(agentName);
};

const ACRONYMS = ['faq', 'api', 'url', 'id', 'sla', 'csat'];

// Tool names arrive as RubyLLM identifiers like
// "captain--tools--faq_lookup" or "custom_get_status_page_overview";
// show "FAQ Lookup" / "Get Status Page Overview" instead.
const humanizeToolName = name => {
  return (name || '')
    .split('--')
    .pop()
    .replace(/^custom_/, '')
    .split('_')
    .filter(Boolean)
    .map(word =>
      ACRONYMS.includes(word)
        ? word.toUpperCase()
        : word.charAt(0).toUpperCase() + word.slice(1)
    )
    .join(' ');
};

// Argument keys are camelCased by the store ("labelName"); show "Label Name".
const humanizeArgumentKey = key =>
  key
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

const formatArguments = args => {
  if (!args || typeof args !== 'object') return '';
  return Object.entries(args)
    .map(([key, value]) => `${humanizeArgumentKey(key)}: ${value}`)
    .join(', ');
};

// Timeline of what Captain did during the run: tool calls (with their
// arguments) and scenario/agent handoffs. Message bodies and raw tool
// results are intentionally not echoed here.
const steps = computed(() => {
  const runContext = session.value?.runContext;
  const result = [];
  let currentAgent = null;

  (Array.isArray(runContext) ? runContext : []).forEach(entry => {
    if (entry?.role !== 'assistant') return;

    const agentName = entry.agentName;
    if (agentName && agentName !== currentAgent) {
      if (currentAgent !== null) {
        result.push({ type: 'handoff', name: handoffLabel(agentName) });
      }
      currentAgent = agentName;
    }

    (entry.toolCalls || []).forEach(call => {
      // Agent-to-agent transfers surface as "handoff_to_<agent>" tool calls;
      // the agent_name change above already yields a handoff step for them.
      if (call.name?.startsWith('handoff_to_')) return;

      result.push({
        type: 'tool',
        name: humanizeToolName(call.name),
        detail: formatArguments(call.arguments),
      });
    });
  });

  return result;
});

// The final assistant entry stores structured content ({response, reasoning});
// surface the model's reasoning for the reply it produced.
const reasoning = computed(() => {
  const runContext = session.value?.runContext;
  if (!Array.isArray(runContext)) return '';

  const entry = [...runContext]
    .reverse()
    .find(item => item?.role === 'assistant' && item.content?.reasoning);
  return entry?.content?.reasoning || '';
});

const STEP_ICONS = {
  tool: 'i-ph-wrench',
  handoff: 'i-ph-user-switch',
};

const STEP_KEYPATHS = {
  tool: 'CONVERSATION.CAPTAIN_GENERATION.STEP_TOOL',
  handoff: 'CONVERSATION.CAPTAIN_GENERATION.STEP_HANDOFF',
};

const currentUser = useMapGetter('getCurrentUser');
const isSuperAdmin = computed(() => currentUser.value.type === 'SuperAdmin');

// Model and credits are only surfaced to super admins and in development.
const devDetails = computed(() => {
  if (!session.value) return null;
  if (!import.meta.env.DEV && !isSuperAdmin.value) return null;
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
    return isOpen.value
      ? 'text-n-amber-12/80'
      : 'text-n-amber-12/40 hover:text-n-amber-12/70';
  }
  return isOpen.value
    ? 'text-n-slate-12'
    : 'text-n-slate-11/60 hover:text-n-slate-12';
});

const popoverAlign = computed(() =>
  orientation.value === ORIENTATION.LEFT ? 'start' : 'end'
);

const prefetch = () => {
  store.dispatch('captainAgentSessions/fetch', {
    messageId: props.messageId,
    createdAt: createdAt.value,
  });
};

const onPopoverShow = () => {
  isOpen.value = true;
  prefetch();
};

const onPopoverHide = () => {
  isOpen.value = false;
};
</script>

<template>
  <div class="flex items-center gap-1.5" :class="rowLayoutClass">
    <Popover
      v-if="showSparkle"
      :align="popoverAlign"
      @show="onPopoverShow"
      @hide="onPopoverHide"
    >
      <button
        v-tooltip="t('CONVERSATION.CAPTAIN_GENERATION.TITLE')"
        type="button"
        class="inline-flex items-center gap-1 p-0 bg-transparent border-0 cursor-pointer"
        :class="sparkleColorClass"
        @mouseenter="prefetch"
        @focus="prefetch"
      >
        <Icon icon="i-ph-sparkle-fill" class="size-3.5" />
        <span class="text-xs">
          {{ t('CONVERSATION.CAPTAIN_GENERATION.GENERATED_BY') }}
        </span>
      </button>
      <template #content>
        <div class="flex flex-col gap-4 p-4 w-80">
          <span v-if="isLoading" class="text-xs text-n-slate-11">
            {{ t('CONVERSATION.CAPTAIN_GENERATION.LOADING') }}
          </span>
          <span v-else-if="!session" class="text-xs text-n-slate-11">
            {{ t('CONVERSATION.CAPTAIN_GENERATION.EMPTY') }}
          </span>
          <template v-else>
            <div v-if="steps.length" class="flex flex-col gap-2">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('CONVERSATION.CAPTAIN_GENERATION.TIMELINE') }}
              </span>
              <div class="flex flex-col">
                <div
                  v-for="(step, index) in steps"
                  :key="index"
                  class="flex gap-2.5"
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
                  <div
                    class="flex flex-col min-w-0 gap-0.5"
                    :class="index < steps.length - 1 ? 'pb-3' : ''"
                  >
                    <I18nT
                      :keypath="STEP_KEYPATHS[step.type]"
                      tag="span"
                      class="text-xs leading-5 text-n-slate-11"
                    >
                      <template #name>
                        <span class="font-medium text-n-slate-12">
                          {{ step.name }}
                        </span>
                      </template>
                    </I18nT>
                    <span
                      v-if="step.detail"
                      class="text-xs text-n-slate-11 break-words"
                    >
                      {{ step.detail }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div v-if="citations.length" class="flex flex-col gap-2">
              <div class="flex items-baseline gap-1.5">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CONVERSATION.CAPTAIN_GENERATION.SOURCES') }}
                </span>
                <span class="text-xs text-n-slate-10">
                  {{
                    t(
                      'CONVERSATION.CAPTAIN_GENERATION.SOURCES_SUMMARY',
                      citations.length
                    )
                  }}
                </span>
              </div>
              <ul class="flex flex-col gap-1 m-0 list-disc ps-4">
                <li
                  v-for="citation in citations"
                  :key="citation.id"
                  class="text-xs text-n-slate-12"
                >
                  <a
                    v-if="citation.link"
                    :href="citation.link"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-xs text-n-blue-11 hover:underline"
                  >
                    {{ citation.title || citation.link }}
                  </a>
                  <span v-else>{{ citation.title }}</span>
                </li>
              </ul>
            </div>
            <div v-if="reasoning" class="flex flex-col gap-2">
              <span class="text-xs font-medium text-n-slate-11">
                {{ t('CONVERSATION.CAPTAIN_GENERATION.REASONING') }}
              </span>
              <p class="m-0 text-xs leading-normal text-n-slate-12 break-words">
                {{ reasoning }}
              </p>
            </div>
            <span v-if="devDetails" class="text-xs text-n-slate-11">
              {{ devDetails }}
            </span>
          </template>
        </div>
      </template>
    </Popover>
    <slot name="meta" />
  </div>
</template>
