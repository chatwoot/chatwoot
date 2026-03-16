<script setup>
import { computed } from 'vue';
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
import { useI18n } from 'vue-i18n';


 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
import { useI18n } from 'vue-i18n';

 develop

 develop
const props = defineProps({
  conversation: {
    type: Object,
    default: () => ({}),
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
});

 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
const { t } = useI18n();


 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
const { t } = useI18n();


 develop
 develop
const conversationAttributes = computed(
  () => props.conversation?.additional_attributes || {}
);

const summary = computed(
  () =>
    conversationAttributes.value.ai_summary ||
    conversationAttributes.value.summary ||
    ''
);

const intent = computed(
  () =>
    conversationAttributes.value.ai_intent ||
    conversationAttributes.value.intent
);

const sentiment = computed(
  () =>
    conversationAttributes.value.ai_sentiment ||
    conversationAttributes.value.sentiment
);

const leadScore = computed(() => {
  const value = Number(
    conversationAttributes.value.lead_score ||
      props.contact?.additional_attributes?.lead_score ||
      0
  );

  return Number.isFinite(value) ? Math.max(0, Math.min(100, value)) : 0;
});

const probabilityToClose = computed(() => {
  const value = Number(conversationAttributes.value.sale_probability || 0);
  return Number.isFinite(value) ? Math.max(0, Math.min(100, value)) : 0;
});

const slaRemaining = computed(
  () => conversationAttributes.value.sla_remaining || '--:--'
);

const suggestedActions = computed(() => {
  const actions = conversationAttributes.value.suggested_actions;
  if (Array.isArray(actions) && actions.length) return actions;

  return [
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.SEND_TEMPLATE',
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.CONFIRM_CONTEXT',
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.TRANSFER_QUEUE',
  ];
});

const knowledgeArticles = computed(() => {
  const items = conversationAttributes.value.knowledge_articles;
  if (Array.isArray(items) && items.length) return items;

  return [
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.BILLING',
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.SLA',
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.HANDOFF',
  ];
});

const nextBestAction = computed(
  () =>
    conversationAttributes.value.next_best_action ||
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_NEXT_ACTION'
);

const isSalesMode = computed(() => {
  const team = String(props.conversation?.meta?.team?.name || '').toLowerCase();
  return team.includes('sales') || team.includes('comercial');
});

const isSupportMode = computed(() => !isSalesMode.value);
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
 develop

const resolveSuggestedAction = action => {
  if (
    action ===
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.SEND_TEMPLATE'
  ) {
    return t(
      'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.SEND_TEMPLATE'
    );
  }

  if (
    action ===
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.CONFIRM_CONTEXT'
  ) {
    return t(
      'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.CONFIRM_CONTEXT'
    );
  }

  if (
    action ===
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.TRANSFER_QUEUE'
  ) {
    return t(
      'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_ACTIONS.TRANSFER_QUEUE'
    );
  }

  return action;
};

const resolveKnowledgeItem = item => {
  if (
    item === 'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.BILLING'
  ) {
    return t(
      'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.BILLING'
    );
  }

  if (item === 'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.SLA') {
    return t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.SLA');
  }

  if (
    item === 'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.HANDOFF'
  ) {
    return t(
      'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_KNOWLEDGE.HANDOFF'
    );
  }

  return item;
};

const resolvedNextBestAction = computed(() => {
  if (
    nextBestAction.value ===
    'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_NEXT_ACTION'
  ) {
    return t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.DEFAULT_NEXT_ACTION');
  }

  return nextBestAction.value;
});
</script>

<template>
  <div class="p-3 rounded-xl border border-n-weak bg-n-solid-2">
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8


</script>

<template>
 codex/transform-chatwoot-into-synapsea-connect-vkjace
  <div class="p-3 rounded-xl border border-n-weak bg-n-solid-2">

  <div
    class="mx-2 mb-3 p-3 rounded-xl border border-n-slate-6 bg-n-background shadow-sm"
  >
 develop
 develop
 develop
    <div class="flex items-center justify-between gap-2 mb-3">
      <h3 class="text-sm font-semibold text-n-slate-12">
        {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.TITLE') }}
      </h3>
      <span
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
        class="text-xs font-medium px-2 py-1 rounded-full bg-n-alpha-2 text-n-slate-11"

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
        class="text-xs font-medium px-2 py-1 rounded-full bg-n-alpha-2 text-n-slate-11"

 codex/transform-chatwoot-into-synapsea-connect-vkjace
        class="text-xs font-medium px-2 py-1 rounded-full bg-n-alpha-2 text-n-slate-11"

        class="text-xs font-medium px-2 py-1 rounded-full bg-n-blue-3 text-n-blue-11"
 develop
 develop
 develop
      >
        {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.COPILOT') }}
      </span>
    </div>

    <div class="grid grid-cols-2 gap-2 mb-3 text-xs">
      <div class="p-2 rounded-lg bg-n-alpha-2">
        <p class="text-n-slate-10">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SLA_REMAINING') }}
        </p>
        <p class="font-semibold text-n-slate-12">{{ slaRemaining }}</p>
      </div>
      <div class="p-2 rounded-lg bg-n-alpha-2">
        <p class="text-n-slate-10">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.LEAD_SCORE') }}
        </p>
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt

 codex/transform-chatwoot-into-synapsea-connect-vkjace
 develop
 develop
        <p class="font-semibold text-n-slate-12">
          {{
            $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.PERCENT_VALUE', {
              value: leadScore,
            })
          }}
        </p>
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt


        <p class="font-semibold text-n-slate-12">{{ leadScore }}%</p>
 develop
 develop
 develop
      </div>
    </div>

    <div class="space-y-3 text-xs">
      <section>
        <p class="font-medium text-n-slate-11 mb-1">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SUMMARY') }}
        </p>
        <p class="text-n-slate-10">
          {{
            summary ||
            $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.EMPTY_SUMMARY')
          }}
        </p>
      </section>

      <section class="grid grid-cols-2 gap-2">
        <div class="rounded-lg border border-n-slate-5 p-2">
          <p class="text-n-slate-10">
            {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.INTENT') }}
          </p>
          <p class="font-medium text-n-slate-12">{{ intent || '--' }}</p>
        </div>
        <div class="rounded-lg border border-n-slate-5 p-2">
          <p class="text-n-slate-10">
            {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SENTIMENT') }}
          </p>
          <p class="font-medium text-n-slate-12">{{ sentiment || '--' }}</p>
        </div>
      </section>

      <section>
        <p class="font-medium text-n-slate-11 mb-1">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.NEXT_ACTION') }}
        </p>
        <p class="text-n-slate-10">
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
          {{ resolvedNextBestAction }}

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
          {{ resolvedNextBestAction }}

          {{
            nextBestAction.includes('.') ? $t(nextBestAction) : nextBestAction
          }}
 develop
 develop
        </p>
      </section>

      <section>
        <p class="font-medium text-n-slate-11 mb-1">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SUGGESTED_ACTIONS') }}
        </p>
        <ul class="space-y-1 text-n-slate-10 list-disc pl-4">
          <li v-for="action in suggestedActions" :key="action">
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
            {{ resolveSuggestedAction(action) }}

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
            {{ resolveSuggestedAction(action) }}

            {{ action.includes('.') ? $t(action) : action }}
 develop
 develop
          </li>
        </ul>
      </section>

      <section>
        <p class="font-medium text-n-slate-11 mb-1">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.KNOWLEDGE') }}
        </p>
        <ul class="space-y-1 text-n-slate-10 list-disc pl-4">
          <li v-for="item in knowledgeArticles" :key="item">
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
            {{ resolveKnowledgeItem(item) }}
 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
            {{ resolveKnowledgeItem(item) }}

            {{ item.includes('.') ? $t(item) : item }}
 develop
 develop
          </li>
        </ul>
      </section>

      <section
        v-if="isSalesMode"
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt

 codex/transform-chatwoot-into-synapsea-connect-vkjace
 develop
 develop
        class="rounded-lg border border-n-weak bg-n-slate-2 p-2"
      >
        <p class="text-n-slate-12 font-medium mb-1">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SALES_MODE') }}
        </p>
        <p class="text-n-slate-11">
          {{
            $t(
              'CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.CLOSE_PROBABILITY_VALUE',
              { value: probabilityToClose }
            )
          }}
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt


        class="rounded-lg border border-n-green-5 p-2"
      >
        <p class="text-n-green-11 font-medium mb-1">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SALES_MODE') }}
        </p>
        <p class="text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.CLOSE_PROBABILITY') }}:
          <span class="font-semibold">{{ probabilityToClose }}%</span>
 develop
 develop
 develop
        </p>
      </section>

      <section
        v-if="isSupportMode"
 codex/transform-chatwoot-into-synapsea-connect-2i3fp8
        class="rounded-lg border border-n-weak bg-n-slate-2 p-2"
      >
        <p class="text-n-slate-12 font-medium mb-1">

 codex/transform-chatwoot-into-synapsea-connect-6xbxtt
        class="rounded-lg border border-n-weak bg-n-slate-2 p-2"
      >
        <p class="text-n-slate-12 font-medium mb-1">

 codex/transform-chatwoot-into-synapsea-connect-vkjace
        class="rounded-lg border border-n-weak bg-n-slate-2 p-2"
      >
        <p class="text-n-slate-12 font-medium mb-1">

        class="rounded-lg border border-n-violet-5 p-2"
      >
        <p class="text-n-violet-11 font-medium mb-1">
 develop
 develop
 develop
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SUPPORT_MODE') }}
        </p>
        <p class="text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.TECH_CONTEXT') }}
        </p>
      </section>
    </div>
  </div>
</template>
