<script setup>
import { computed, markRaw, nextTick, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { MarkerType, VueFlow, useVueFlow } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { Graph, layout as dagreLayout } from '@dagrejs/dagre';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { FLOW_ACTION_TYPES } from './constants';
import FlowStepNode from './FlowStepNode.vue';
import FlowTerminalNode from './FlowTerminalNode.vue';

import '@vue-flow/core/dist/style.css';
import '@vue-flow/core/dist/theme-default.css';
import '@vue-flow/controls/dist/style.css';

const props = defineProps({
  steps: { type: Array, required: true },
  selectedStepId: { type: String, default: null },
});

const emit = defineEmits([
  'selectStep',
  'addStep',
  'removeStep',
  'connectBranch',
]);

const TERMINAL_END = '__terminal_end';
const TERMINAL_HANDOFF = '__terminal_handoff';
const NODE_WIDTH = 200;
const NODE_HEIGHT = 72;
const TERMINAL_W = 120;
const TERMINAL_H = 36;

const { t } = useI18n();
const { fitView } = useVueFlow({ id: 'flow-editor' });

const nodeTypes = {
  step: markRaw(FlowStepNode),
  terminal: markRaw(FlowTerminalNode),
};

const nodes = ref([]);
const edges = ref([]);
const isFirstLayout = ref(true);
const prevStepCount = ref(0);
let contentTimer = null;

const messagePreview = step => {
  const send = (step.actions || []).find(a => a.action_name === 'send_message');
  if (send) {
    const content = Array.isArray(send.action_params)
      ? send.action_params[0]
      : send.action_params;
    if (typeof content === 'string' && content.trim()) {
      return content.slice(0, 48);
    }
  }
  const first = step.actions?.[0]?.action_name;
  const type = FLOW_ACTION_TYPES.find(a => a.key === first);
  return type ? t(`AUTOMATION.ACTIONS.${type.label}`) : step.id;
};

const filledButtons = step =>
  (step.buttons || []).filter(b => (b.title || '').trim());

const branchTarget = (step, btnIndex) => {
  const target = step.branches?.[btnIndex];
  if (!target || target === 'end') return TERMINAL_END;
  if (target === 'handoff') return TERMINAL_HANDOFF;
  if (props.steps.some(s => s.id === target)) return target;
  return TERMINAL_END;
};

const structureKey = computed(() =>
  JSON.stringify(
    props.steps.map(s => ({
      id: s.id,
      buttons: filledButtons(s).map(b => ({
        idx: s.buttons.indexOf(b),
        to: s.branches?.[s.buttons.indexOf(b)] || 'end',
      })),
    }))
  )
);

const contentKey = computed(() =>
  props.steps
    .map(
      s =>
        `${s.id}:${s.title || ''}:${messagePreview(s)}:${filledButtons(s)
          .map(b => b.title)
          .join(',')}`
    )
    .join('|')
);

const safeFitView = async () => {
  await nextTick();
  try {
    fitView({ padding: 0.2, duration: 200 });
  } catch {
    // store may not be ready
  }
};

const applyLayout = (rawNodes, rawEdges) => {
  const g = new Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({
    rankdir: 'TB',
    nodesep: 56,
    ranksep: 80,
    marginx: 24,
    marginy: 24,
  });

  rawNodes.forEach(node => {
    const isTerminal = node.type === 'terminal';
    g.setNode(node.id, {
      width: isTerminal ? TERMINAL_W : NODE_WIDTH,
      height: isTerminal ? TERMINAL_H : NODE_HEIGHT,
    });
  });
  rawEdges.forEach(edge => {
    if (g.hasNode(edge.source) && g.hasNode(edge.target)) {
      g.setEdge(edge.source, edge.target);
    }
  });

  dagreLayout(g);

  return rawNodes.map(node => {
    const pos = g.node(node.id);
    const isTerminal = node.type === 'terminal';
    const w = isTerminal ? TERMINAL_W : NODE_WIDTH;
    const h = isTerminal ? TERMINAL_H : NODE_HEIGHT;
    return {
      ...node,
      position: {
        x: (pos?.x || 0) - w / 2,
        y: (pos?.y || 0) - h / 2,
      },
    };
  });
};

const buildStepData = (step, index) => ({
  title: step.title || '',
  label: messagePreview(step),
  buttons: step.buttons || [],
  stepIndex: index,
  canRemove: props.steps.length > 1,
  onRemove: idx => emit('removeStep', idx),
});

const rebuild = async ({ shouldFit = false } = {}) => {
  const rawNodes = props.steps.map((step, index) => ({
    id: step.id,
    type: 'step',
    position: { x: 0, y: 0 },
    selected: step.id === props.selectedStepId,
    data: buildStepData(step, index),
  }));

  const needsEnd = props.steps.some((step, index) => {
    const buttons = filledButtons(step);
    if (buttons.length) {
      return buttons.some(btn => {
        const btnIndex = step.buttons.indexOf(btn);
        return branchTarget(step, btnIndex) === TERMINAL_END;
      });
    }
    return !props.steps[index + 1];
  });

  const needsHandoff = props.steps.some(step =>
    filledButtons(step).some(btn => {
      const btnIndex = step.buttons.indexOf(btn);
      return branchTarget(step, btnIndex) === TERMINAL_HANDOFF;
    })
  );

  if (needsEnd) {
    rawNodes.push({
      id: TERMINAL_END,
      type: 'terminal',
      position: { x: 0, y: 0 },
      selectable: false,
      data: { kind: 'end', label: t('FLOWS.EDIT.BRANCH_END') },
    });
  }

  if (needsHandoff) {
    rawNodes.push({
      id: TERMINAL_HANDOFF,
      type: 'terminal',
      position: { x: 0, y: 0 },
      selectable: false,
      data: { kind: 'handoff', label: t('FLOWS.EDIT.BRANCH_HANDOFF') },
    });
  }

  const rawEdges = [];
  props.steps.forEach((step, index) => {
    const buttons = filledButtons(step);
    if (buttons.length) {
      buttons.forEach(btn => {
        const btnIndex = step.buttons.indexOf(btn);
        const target = branchTarget(step, btnIndex);
        rawEdges.push({
          id: `e-${step.id}-b${btnIndex}-${target}`,
          source: step.id,
          sourceHandle: `btn-${btnIndex}`,
          target,
          label: btn.title,
          markerEnd: MarkerType.ArrowClosed,
          animated: target === TERMINAL_HANDOFF,
          style: {
            stroke: target === TERMINAL_HANDOFF ? '#e5484d' : '#978365',
          },
          labelStyle: { fontSize: 10, fill: '#6f6e77' },
          labelBgStyle: { fill: 'transparent' },
        });
      });
    } else {
      const next = props.steps[index + 1];
      const target = next ? next.id : TERMINAL_END;
      rawEdges.push({
        id: `e-${step.id}-next-${target}`,
        source: step.id,
        sourceHandle: 'out',
        target,
        markerEnd: MarkerType.ArrowClosed,
        style: { stroke: '#8da4ef' },
      });
    }
  });

  nodes.value = applyLayout(rawNodes, rawEdges);
  edges.value = rawEdges;

  if (shouldFit) await safeFitView();
};

const syncNodeContent = () => {
  nodes.value = nodes.value.map(node => {
    if (node.type !== 'step') return node;
    const step = props.steps.find(s => s.id === node.id);
    if (!step) return node;
    const index = props.steps.indexOf(step);
    return {
      ...node,
      selected: step.id === props.selectedStepId,
      data: buildStepData(step, index),
    };
  });

  edges.value = edges.value.map(edge => {
    const step = props.steps.find(s => s.id === edge.source);
    if (!step) return edge;
    const match = edge.id.match(/-b(\d+)-/);
    if (!match) return edge;
    const btnIndex = Number(match[1]);
    const title = step.buttons?.[btnIndex]?.title;
    if (!title || edge.label === title) return edge;
    return { ...edge, label: title };
  });
};

watch(
  structureKey,
  () => {
    const count = props.steps.length;
    const fit = isFirstLayout.value || count !== prevStepCount.value;
    prevStepCount.value = count;
    isFirstLayout.value = false;
    rebuild({ shouldFit: fit });
  },
  { immediate: true }
);

watch(contentKey, () => {
  clearTimeout(contentTimer);
  contentTimer = setTimeout(() => {
    syncNodeContent();
  }, 120);
});

watch(
  () => props.selectedStepId,
  () => {
    nodes.value = nodes.value.map(node =>
      node.type === 'step'
        ? { ...node, selected: node.id === props.selectedStepId }
        : node
    );
  }
);

onUnmounted(() => {
  clearTimeout(contentTimer);
});

const onNodeClick = ({ node }) => {
  if (node.type === 'step') emit('selectStep', node.id);
};

const onConnect = connection => {
  if (!connection.source || !connection.target) return;
  if (connection.source === connection.target) return;
  if ([TERMINAL_END, TERMINAL_HANDOFF].includes(connection.source)) return;

  let target = connection.target;
  if (target === TERMINAL_END) target = 'end';
  else if (target === TERMINAL_HANDOFF) target = 'handoff';
  else if (!props.steps.some(s => s.id === target)) return;

  emit('connectBranch', {
    sourceId: connection.source,
    targetId: target,
    sourceHandle: connection.sourceHandle || null,
  });
};

const onAddStep = () => {
  emit('addStep');
};
</script>

<template>
  <div class="flex flex-col gap-2 h-full min-h-0 w-full">
    <div class="flex items-center justify-between gap-2 flex-shrink-0">
      <p class="m-0 text-xs text-n-slate-11">
        {{ t('FLOWS.EDIT.CANVAS_HINT') }}
      </p>
      <NextButton
        solid
        teal
        sm
        icon="i-lucide-plus-circle"
        :label="t('FLOWS.EDIT.ADD_BTN_TOOLTIP')"
        @click="onAddStep"
      />
    </div>

    <div
      class="relative flex-1 min-h-0 rounded-lg border border-n-weak overflow-hidden bg-n-background dark:bg-n-solid-1"
    >
      <VueFlow
        id="flow-editor"
        v-model:nodes="nodes"
        v-model:edges="edges"
        :node-types="nodeTypes"
        nodes-draggable
        nodes-connectable
        elements-selectable
        :default-edge-options="{ type: 'smoothstep' }"
        fit-view-on-init
        class="h-full w-full"
        @node-click="onNodeClick"
        @connect="onConnect"
      >
        <Background pattern-color="#94a3b8" :gap="16" :size="1" />
        <Controls position="bottom-left" />
      </VueFlow>
    </div>
  </div>
</template>
