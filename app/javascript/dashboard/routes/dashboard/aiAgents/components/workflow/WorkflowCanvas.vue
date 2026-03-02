<script setup>
import { VueFlow } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { MiniMap } from '@vue-flow/minimap';
import { Controls } from '@vue-flow/controls';
import '@vue-flow/core/dist/style.css';
import '@vue-flow/core/dist/theme-default.css';
import '@vue-flow/minimap/dist/style.css';
import '@vue-flow/controls/dist/style.css';

import TriggerNode from './nodes/TriggerNode.vue';
import SystemPromptNode from './nodes/SystemPromptNode.vue';
import KnowledgeRetrievalNode from './nodes/KnowledgeRetrievalNode.vue';
import LlmCallNode from './nodes/LlmCallNode.vue';
import ConditionNode from './nodes/ConditionNode.vue';
import LoopNode from './nodes/LoopNode.vue';
import SetVariableNode from './nodes/SetVariableNode.vue';
import DelayNode from './nodes/DelayNode.vue';
import HttpRequestNode from './nodes/HttpRequestNode.vue';
import HandoffNode from './nodes/HandoffNode.vue';
import ReplyNode from './nodes/ReplyNode.vue';
import CodeNode from './nodes/CodeNode.vue';

defineProps({
  nodes: { type: Array, required: true },
  edges: { type: Array, required: true },
  isValidConnection: { type: Function, default: () => true },
});

const emit = defineEmits([
  'nodesChange',
  'edgesChange',
  'nodeClick',
  'paneClick',
  'drop',
  'dragover',
]);

const nodeTypes = {
  trigger: TriggerNode,
  system_prompt: SystemPromptNode,
  knowledge_retrieval: KnowledgeRetrievalNode,
  llm_call: LlmCallNode,
  condition: ConditionNode,
  loop: LoopNode,
  set_variable: SetVariableNode,
  delay: DelayNode,
  http_request: HttpRequestNode,
  handoff: HandoffNode,
  reply: ReplyNode,
  code: CodeNode,
};

function onDragOver(event) {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
  emit('dragover', event);
}

function onDrop(event) {
  emit('drop', event);
}

function onNodeClick(event) {
  emit('nodeClick', event);
}

function onPaneClick() {
  emit('paneClick');
}
</script>

<template>
  <div class="size-full">
    <VueFlow
      :nodes="nodes"
      :edges="edges"
      :node-types="nodeTypes"
      :is-valid-connection="isValidConnection"
      :default-edge-options="{ type: 'smoothstep', animated: true }"
      snap-to-grid
      :snap-grid="[20, 20]"
      fit-view-on-init
      class="size-full"
      @nodes-change="$emit('nodesChange', $event)"
      @edges-change="$emit('edgesChange', $event)"
      @node-click="onNodeClick"
      @pane-click="onPaneClick"
      @dragover="onDragOver"
      @drop="onDrop"
    >
      <Background
        :gap="20"
        :size="1"
        pattern-color="rgba(148, 163, 184, 0.15)"
      />
      <MiniMap class="!bottom-4 !right-4" />
      <Controls class="!bottom-4 !left-4" />
    </VueFlow>
  </div>
</template>
