<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const NODE_CATEGORIES = [
  {
    label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.PALETTE.TRIGGERS',
    color: 'n-teal',
    icon: 'i-lucide-zap',
    nodes: [
      {
        type: 'trigger_conversation_created',
        label:
          'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.TRIGGER_CONVERSATION_CREATED',
      },
      {
        type: 'trigger_message_created',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.TRIGGER_MESSAGE_CREATED',
      },
      {
        type: 'trigger_conversation_resolved',
        label:
          'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.TRIGGER_CONVERSATION_RESOLVED',
      },
    ],
  },
  {
    label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.PALETTE.LOGIC',
    color: 'n-amber',
    icon: 'i-lucide-git-branch',
    nodes: [
      {
        type: 'condition',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.CONDITION',
      },
    ],
  },
  {
    label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.PALETTE.ACTIONS',
    color: 'n-blue',
    icon: 'i-lucide-play',
    nodes: [
      {
        type: 'send_message',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.SEND_MESSAGE',
      },
      {
        type: 'add_label',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.ADD_LABEL',
      },
      {
        type: 'assign_agent',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.ASSIGN_AGENT',
      },
      {
        type: 'assign_team',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.ASSIGN_TEAM',
      },
      {
        type: 'resolve_conversation',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.RESOLVE_CONVERSATION',
      },
      {
        type: 'add_private_note',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.ADD_PRIVATE_NOTE',
      },
      {
        type: 'update_priority',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.UPDATE_PRIORITY',
      },
    ],
  },
  {
    label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.PALETTE.SHOPIFY',
    color: 'n-teal',
    icon: 'i-lucide-shopping-bag',
    nodes: [
      {
        type: 'shopify_search_customer',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.SHOPIFY_SEARCH_CUSTOMER',
      },
      {
        type: 'shopify_get_customer_orders',
        label: 'CAPTAIN.ASSISTANTS.WORKFLOWS.NODES.SHOPIFY_GET_CUSTOMER_ORDERS',
      },
    ],
  },
];

const onDragStart = (event, type) => {
  event.dataTransfer.setData('application/captainnode', type);
  event.dataTransfer.effectAllowed = 'move';
};
</script>

<template>
  <div
    class="w-60 shrink-0 border-r border-n-weak bg-n-solid-2 overflow-y-auto"
  >
    <div class="p-3 flex flex-col gap-4">
      <div v-for="category in NODE_CATEGORIES" :key="category.label">
        <div class="flex items-center gap-1.5 mb-2 px-1">
          <span class="size-3 text-n-slate-10" :class="[category.icon]" />
          <h4 class="text-[11px] font-semibold text-n-slate-10 uppercase">
            {{ t(category.label) }}
          </h4>
        </div>
        <div class="flex flex-col gap-1">
          <div
            v-for="node in category.nodes"
            :key="node.type"
            class="flex items-center gap-2 px-2.5 py-2 text-xs text-n-slate-12 rounded-lg cursor-grab bg-n-solid-2 hover:bg-n-alpha-2 outline outline-1 -outline-offset-1 outline-n-container transition-colors"
            draggable="true"
            @dragstart="e => onDragStart(e, node.type)"
          >
            {{ t(node.label) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
