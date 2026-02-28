<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { VueFlow, useVueFlow } from '@vue-flow/core';

import WorkflowToolbar from 'dashboard/components-next/captain/workflows/WorkflowToolbar.vue';
import NodePalette from 'dashboard/components-next/captain/workflows/NodePalette.vue';
import NodeConfigPanel from 'dashboard/components-next/captain/workflows/NodeConfigPanel.vue';
import ActionNode from 'dashboard/components-next/captain/workflows/nodes/ActionNode.vue';
import ConditionNode from 'dashboard/components-next/captain/workflows/nodes/ConditionNode.vue';
import ShopifyNode from 'dashboard/components-next/captain/workflows/nodes/ShopifyNode.vue';
import CollectInputNode from 'dashboard/components-next/captain/workflows/nodes/CollectInputNode.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const assistantId = computed(() => Number(route.params.assistantId));
const workflowId = computed(() => Number(route.params.workflowId));
const workflow = computed(() =>
  store.getters['captainWorkflows/getRecord'](workflowId.value)
);

const selectedNode = ref(null);

const { onConnect, addEdges, project } = useVueFlow();
const nodes = ref([]);
const edges = ref([]);

const nodeTypes = {
  collect_input: CollectInputNode,
  condition: ConditionNode,
  send_message: ActionNode,
  add_label: ActionNode,
  assign_agent: ActionNode,
  assign_team: ActionNode,
  resolve_conversation: ActionNode,
  add_private_note: ActionNode,
  update_priority: ActionNode,
  shopify_search_customer: ShopifyNode,
  shopify_get_customer_orders: ShopifyNode,
};

watch(workflow, val => {
  if (val && val.id) {
    nodes.value = (val.nodes || []).map(n => ({
      ...n,
      type: n.type,
    }));
    edges.value = val.edges || [];
  }
});

onConnect(params => {
  addEdges([params]);
});

const onDragOver = event => {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
};

const onDrop = event => {
  const type = event.dataTransfer.getData('application/captainnode');
  if (!type) return;

  const { left, top } = event.currentTarget.getBoundingClientRect();
  const position = project({
    x: event.clientX - left,
    y: event.clientY - top,
  });

  const newNode = {
    id: `node_${Date.now()}`,
    type,
    position,
    data: { label: type.replace(/_/g, ' ') },
  };
  nodes.value = [...nodes.value, newNode];
};

const onNodeClick = (_event, node) => {
  selectedNode.value = node;
};

const onPaneClick = () => {
  selectedNode.value = null;
};

const updateNodeData = (nodeId, data) => {
  nodes.value = nodes.value.map(n =>
    n.id === nodeId ? { ...n, data: { ...n.data, ...data } } : n
  );
  if (selectedNode.value?.id === nodeId) {
    selectedNode.value = {
      ...selectedNode.value,
      data: { ...selectedNode.value.data, ...data },
    };
  }
};

const deleteNode = nodeId => {
  nodes.value = nodes.value.filter(n => n.id !== nodeId);
  edges.value = edges.value.filter(
    e => e.source !== nodeId && e.target !== nodeId
  );
  if (selectedNode.value?.id === nodeId) {
    selectedNode.value = null;
  }
};

const saveWorkflow = async ({ name, description, enabled }) => {
  try {
    await store.dispatch('captainWorkflows/update', {
      id: workflowId.value,
      assistantId: assistantId.value,
      name,
      description,
      enabled,
      nodes: nodes.value.map(n => ({
        id: n.id,
        type: n.type,
        position: n.position,
        data: n.data,
      })),
      edges: edges.value.map(e => ({
        id: e.id,
        source: e.source,
        sourceHandle: e.sourceHandle,
        target: e.target,
        targetHandle: e.targetHandle,
      })),
    });
    useAlert(t('CAPTAIN.ASSISTANTS.WORKFLOWS.API.UPDATE.SUCCESS'));
  } catch (error) {
    useAlert(
      error?.response?.message ||
        t('CAPTAIN.ASSISTANTS.WORKFLOWS.API.UPDATE.ERROR')
    );
  }
};

const goBack = () => {
  router.push({
    name: 'captain_assistants_workflows_index',
    params: {
      accountId: route.params.accountId,
      assistantId: assistantId.value,
    },
  });
};

onMounted(async () => {
  await store.dispatch('captainWorkflows/show', {
    assistantId: assistantId.value,
    id: workflowId.value,
  });
});
</script>

<template>
  <div class="flex flex-col h-full w-full bg-n-surface-1">
    <WorkflowToolbar :workflow="workflow" @save="saveWorkflow" @back="goBack" />
    <div class="flex flex-1 min-h-0">
      <NodePalette />
      <div class="flex-1 relative" @dragover="onDragOver" @drop="onDrop">
        <VueFlow
          v-model:nodes="nodes"
          v-model:edges="edges"
          :node-types="nodeTypes"
          :default-viewport="{ zoom: 1 }"
          fit-view-on-init
          class="w-full h-full"
          @node-click="onNodeClick"
          @pane-click="onPaneClick"
        />
      </div>
      <NodeConfigPanel
        v-if="selectedNode"
        :node="selectedNode"
        @update="updateNodeData"
        @delete="deleteNode"
        @close="selectedNode = null"
      />
    </div>
  </div>
</template>

<style>
.vue-flow__node {
  padding: 0;
  border-radius: 0;
  border: none;
  background: none;
  box-shadow: none;
  font-size: inherit;
  min-width: 0;
}

.vue-flow__handle {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  border: 1px solid white;
  min-width: 0;
  min-height: 0;
}

.vue-flow__edge-path {
  stroke: var(--n-alpha-7);
  stroke-width: 1.5;
}

.vue-flow__edge.selected .vue-flow__edge-path,
.vue-flow__edge:hover .vue-flow__edge-path {
  stroke: var(--n-slate-9);
  stroke-width: 2;
}

.vue-flow__connection-line {
  stroke: var(--n-slate-9);
  stroke-width: 1.5;
}
</style>
