<script setup>
import { watch, onMounted, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useWorkflowEditor } from '../../composables/useWorkflowEditor';

import WorkflowCanvas from '../workflow/WorkflowCanvas.vue';
import NodePalette from '../workflow/NodePalette.vue';
import WorkflowToolbar from '../workflow/WorkflowToolbar.vue';
import NodeConfigPanel from '../workflow/NodeConfigPanel.vue';
import TemplatePicker from '../workflow/TemplatePicker.vue';

const props = defineProps({
  agent: { type: Object, required: true },
});

const store = useStore();
const uiFlags = useMapGetter('aiAgents/getUIFlags');
const isSaving = computed(() => uiFlags.value.isUpdating);

const {
  nodes,
  edges,
  onNodesChange,
  onEdgesChange,
  fitView,
  project,
  isDirty,
  selectedNodeId,
  selectedNode,
  addNode,
  removeNode,
  selectNode,
  deselectNode,
  updateNodeData,
  autoLayout,
  loadWorkflow,
  toWorkflowJson,
  isValidConnection,
} = useWorkflowEditor();

// Load workflow from agent on mount
onMounted(() => {
  if (props.agent?.workflow) {
    loadWorkflow(props.agent.workflow);
  }
});

// Reload if agent changes
watch(
  () => props.agent?.id,
  () => {
    if (props.agent?.workflow) {
      loadWorkflow(props.agent.workflow);
    }
  }
);

// Handle node drop from palette
function onDrop(event) {
  const nodeType = event.dataTransfer.getData('application/workflow-node');
  if (!nodeType) return;

  const bounds = event.currentTarget.getBoundingClientRect();
  const position = project({
    x: event.clientX - bounds.left,
    y: event.clientY - bounds.top,
  });

  addNode(nodeType, position);
}

// Handle node click to open config
function onNodeClick({ node }) {
  selectNode(node.id);
}

// Save workflow
async function saveWorkflow() {
  const workflowJson = toWorkflowJson({
    name: props.agent.name,
    description: props.agent.description,
  });

  await store.dispatch('aiAgents/saveWorkflow', {
    id: props.agent.id,
    workflow: workflowJson,
  });
  isDirty.value = false;
}

// Delete selected node
function deleteSelected() {
  if (selectedNodeId.value) {
    removeNode(selectedNodeId.value);
  }
}

// Handle node update from config panel
function onNodeUpdate(nodeId, data) {
  updateNodeData(nodeId, data);
}

// Handle node delete from config panel
function onNodeDelete(nodeId) {
  removeNode(nodeId);
}

// Handle template selection
function onSelectTemplate(template) {
  loadWorkflow(template);
}

const hasNodes = computed(() => nodes.value.length > 0);
</script>

<template>
  <div
    class="flex h-[calc(100vh-12rem)] overflow-hidden rounded-xl border border-n-weak"
  >
    <!-- Left: Node Palette -->
    <NodePalette />

    <!-- Center: Canvas -->
    <div class="flex flex-1 flex-col">
      <WorkflowToolbar
        :is-dirty="isDirty"
        :is-saving="isSaving"
        @save="saveWorkflow"
        @auto-layout="autoLayout"
        @fit-view="fitView"
        @delete-selected="deleteSelected"
      />
      <div class="flex-1">
        <TemplatePicker v-if="!hasNodes" @select-template="onSelectTemplate" />
        <WorkflowCanvas
          v-else
          :nodes="nodes"
          :edges="edges"
          :is-valid-connection="isValidConnection"
          @nodes-change="onNodesChange"
          @edges-change="onEdgesChange"
          @node-click="onNodeClick"
          @pane-click="deselectNode"
          @drop="onDrop"
        />
      </div>
    </div>

    <!-- Right: Config Panel -->
    <NodeConfigPanel
      v-if="selectedNode"
      :node="selectedNode"
      @update="onNodeUpdate"
      @close="deselectNode"
      @delete="onNodeDelete"
    />
  </div>
</template>
