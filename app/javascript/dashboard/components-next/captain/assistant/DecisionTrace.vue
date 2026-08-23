<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { nodes } = defineProps({
  nodes: {
    type: Array,
    default: () => [],
  },
});

const { t } = useI18n();

const showRawLog = ref(false);

const rawLog = computed(() => JSON.stringify(nodes, null, 2));

const NODE_ICONS = {
  agent_activated: 'i-ph-bot',
  tool_call: 'i-ph-wrench',
  tool_result: 'i-ph-check-circle',
  agent_handoff: 'i-ph-user-switch',
  final_response: 'i-ph-chat-circle-text',
};

const iconFor = node => NODE_ICONS[node.type] || 'i-ph-dots-three';

const nodeTitle = node => {
  switch (node.type) {
    case 'agent_activated':
      return t('CAPTAIN.DECISION_TRACE.AGENT_ACTIVATED', {
        agent: node.agent || node.agentKey,
      });
    case 'tool_call':
      return t('CAPTAIN.DECISION_TRACE.TOOL_CALL', { tool: node.tool });
    case 'tool_result':
      return t('CAPTAIN.DECISION_TRACE.TOOL_RESULT', { tool: node.tool });
    case 'agent_handoff':
      return t('CAPTAIN.DECISION_TRACE.AGENT_HANDOFF', {
        from: node.fromAgent || node.fromAgentKey,
        to: node.toAgent || node.toAgentKey,
      });
    case 'final_response':
      return t('CAPTAIN.DECISION_TRACE.FINAL_RESPONSE', {
        agent: node.agent,
      });
    default:
      return '';
  }
};

const formatArguments = args => {
  if (!args) return '';
  if (typeof args === 'string') return args;
  try {
    return JSON.stringify(args, null, 2);
  } catch {
    return String(args);
  }
};

const hasToolArguments = node => node.type === 'tool_call' && node.arguments;
const hasToolResult = node => node.type === 'tool_result' && node.result;
</script>

<template>
  <div class="flex flex-col gap-2">
    <div v-for="(node, index) in nodes" :key="index" class="flex gap-2.5">
      <div class="flex flex-col items-center">
        <span
          class="flex items-center justify-center rounded-full size-5 bg-n-alpha-2 text-n-slate-11"
        >
          <Icon :icon="iconFor(node)" class="size-3" />
        </span>
        <span
          v-if="index < nodes.length - 1"
          class="flex-1 w-px min-h-2 bg-n-weak"
        />
      </div>
      <div class="flex flex-col min-w-0 gap-1 pb-3">
        <span class="text-xs font-medium text-n-slate-12">
          {{ nodeTitle(node) }}
        </span>
        <span
          v-if="node.type === 'agent_handoff' && node.reason"
          class="text-xs text-n-slate-11"
        >
          {{ node.reason }}
        </span>
        <span
          v-if="node.input || (node.type === 'final_response' && node.response)"
          class="text-xs text-n-slate-11 whitespace-pre-wrap break-words"
        >
          {{ node.input || node.response }}
        </span>
        <span
          v-if="hasToolArguments"
          class="text-xs text-n-slate-11 whitespace-pre-wrap break-words"
        >
          {{ formatArguments(node.arguments) }}
        </span>
        <span
          v-if="hasToolResult"
          class="text-xs text-n-slate-11 whitespace-pre-wrap break-words"
        >
          {{ node.result }}
        </span>
      </div>
    </div>

    <div v-if="nodes.length" class="flex justify-end">
      <button
        type="button"
        class="flex items-center gap-1 text-xs text-n-slate-11 cursor-pointer bg-transparent border-0"
        @click="showRawLog = !showRawLog"
      >
        <Icon
          :icon="showRawLog ? 'i-ph-eye-slash' : 'i-ph-eye'"
          class="size-3"
        />
        {{
          showRawLog
            ? t('CAPTAIN.DECISION_TRACE.HIDE_RAW')
            : t('CAPTAIN.DECISION_TRACE.SHOW_RAW')
        }}
      </button>
    </div>

    <pre
      v-if="showRawLog"
      class="text-xs text-n-slate-11 p-3 bg-n-alpha-2 rounded-xl overflow-x-auto whitespace-pre-wrap break-words"
    >
      {{ rawLog }}
    </pre>
  </div>
</template>
