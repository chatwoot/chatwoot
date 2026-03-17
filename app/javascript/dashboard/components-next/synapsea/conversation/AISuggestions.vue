<script setup>
import { computed } from 'vue';
import SynCard from '../ui/SynCard.vue';
import SynBadge from '../ui/SynBadge.vue';

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

const attrs = computed(() => props.conversation?.additional_attributes || {});
const summary = computed(
  () => attrs.value.ai_summary || attrs.value.summary || ''
);
const intent = computed(
  () => attrs.value.ai_intent || attrs.value.intent || '--'
);
const sentiment = computed(
  () => attrs.value.ai_sentiment || attrs.value.sentiment || '--'
);
const leadScore = computed(
  () =>
    Number(
      attrs.value.lead_score ||
        props.contact?.additional_attributes?.lead_score ||
        0
    ) || 0
);
</script>

<template>
  <SynCard :title="$t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.TITLE')">
    <div class="mb-2 flex items-center justify-between gap-2">
      <p class="text-xs font-medium text-n-slate-11">
        {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SUMMARY') }}
      </p>
      <SynBadge :label="$t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.COPILOT')" />
    </div>

    <p class="mb-3 text-xs text-n-slate-10">
      {{
        summary || $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.EMPTY_SUMMARY')
      }}
    </p>

    <div class="grid grid-cols-3 gap-2 text-xs">
      <div class="rounded-lg border border-n-weak bg-n-slate-2 p-2">
        <p class="text-n-slate-10">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.INTENT') }}
        </p>
        <p class="font-medium text-n-slate-12">{{ intent }}</p>
      </div>
      <div class="rounded-lg border border-n-weak bg-n-slate-2 p-2">
        <p class="text-n-slate-10">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.SENTIMENT') }}
        </p>
        <p class="font-medium text-n-slate-12">{{ sentiment }}</p>
      </div>
      <div class="rounded-lg border border-n-weak bg-n-slate-2 p-2">
        <p class="text-n-slate-10">
          {{ $t('CONVERSATION_SIDEBAR.INTELLIGENT_PANEL.LEAD_SCORE') }}
        </p>
        <p class="font-medium text-n-slate-12">{{ leadScore }}</p>
      </div>
    </div>
  </SynCard>
</template>
