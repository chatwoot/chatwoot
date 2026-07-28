<script setup>
import { computed, markRaw, nextTick, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { MarkerType, VueFlow, useVueFlow } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { MiniMap } from '@vue-flow/minimap';
import { Graph, layout as dagreLayout } from '@dagrejs/dagre';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';
import { FLOW_ACTION_TYPES } from './constants';
import FlowStepNode from './FlowStepNode.vue';
import FlowTerminalNode from './FlowTerminalNode.vue';

import '@vue-flow/core/dist/style.css';
import '@vue-flow/core/dist/theme-default.css';
import '@vue-flow/controls/dist/style.css';
import '@vue-flow/minimap/dist/style.css';

const props = defineProps({
  steps: { type: Array, required: true },
  selectedStepId: { type: String, default: null },
  layoutPositions: { type: Object, default: () => ({}) },
  viewport: {
    type: Object,
    default: () => ({ x: 0, y: 0, zoom: 1 }),
  },
});

const emit = defineEmits([
  'selectStep',
  'addStep',
  'removeStep',
  'connectBranch',
  'update:layoutPositions',
  'update:viewport',
]);

const TERMINAL_END = '__terminal_end';
const TERMINAL_HANDOFF = '__terminal_handoff';
const NODE_WIDTH = 200;
const NODE_HEIGHT_BASE = 72;
const BUTTON_ROW_H = 28;
const TERMINAL_W = 120;
const TERMINAL_H = 36;
const SNAP = 16;
const MINIMAP_STEP_LIMIT = 40;

const { t } = useI18n();
const { fitView, setViewport, getViewport } = useVueFlow({ id: 'flow-editor' });

const nodeTypes = {
  step: markRaw(FlowStepNode),
  terminal: markRaw(FlowTerminalNode),
};

const nodes = ref([]);
const edges = ref([]);
const isFirstLayout = ref(true);
const prevStepCount = ref(0);
const viewportApplied = ref(false);
let contentTimer = null;
let viewportTimer = null;

const showMiniMap = computed(() => props.steps.length < MINIMAP_STEP_LIMIT);

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

const stepHeight = step =>
  NODE_HEIGHT_BASE + filledButtons(step).length * BUTTON_ROW_H;

const branchTarget = (step, btnIndex) => {
  const target = step.branches?.[btnIndex];
  if (!target || target === 'end') return TERMINAL_END;
  if (target === 'handoff') return TERMINAL_HANDOFF;
  if (props.steps.some(s => s.id === target)) return target;
  return TERMINAL_END;
};

const linearTarget = step => {
  const next = step.next || 'end';
  if (next === 'end') return TERMINAL_END;
  if (next === 'handoff') return TERMINAL_HANDOFF;
  if (props.steps.some(s => s.id === next)) return next;
  return TERMINAL_END;
};

const hasBrokenNext = step => {
  if (filledButtons(step).length) return false;
  const next = step.next || 'end';
  if (next === 'end' || next === 'handoff') return false;
  return !props.steps.some(s => s.id === next);
};

const hasBrokenBranch = step =>
  filledButtons(step).some(btn => {
    const btnIndex = step.buttons.indexOf(btn);
    const target = step.branches?.[btnIndex];
    if (!target || target === 'end' || target === 'handoff') return false;
    return !props.steps.some(s => s.id === target);
  }) || hasBrokenNext(step);

const structureKey = computed(() =>
  JSON.stringify(
    props.steps.map(s => ({
      id: s.id,
      next: filledButtons(s).length ? null : s.next || 'end',
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
          .join(',')}:${hasBrokenBranch(s) ? '1' : '0'}`
    )
    .join('|')
);

const truncateLabel = (text, max = 18) => {
  const value = (text || '').trim();
  if (value.length <= max) return value;
  return `${value.slice(0, max - 1)}…`;
};

const safeFitView = async () => {
  await nextTick();
  try {
    fitView({ padding: 0.2, duration: 200 });
  } catch {
    // store may not be ready
  }
};

const applyViewportIfNeeded = async () => {
  if (viewportApplied.value) return;
  const vp = props.viewport;
  if (
    vp &&
    typeof vp.zoom === 'number' &&
    vp.zoom > 0 &&
    (vp.x !== 0 || vp.y !== 0 || vp.zoom !== 1)
  ) {
    await nextTick();
    try {
      setViewport({ x: vp.x || 0, y: vp.y || 0, zoom: vp.zoom });
      viewportApplied.value = true;
    } catch {
      // fall through to fitView
    }
  }
};

const nodeSize = node => {
  if (node.type === 'terminal') {
    return { width: TERMINAL_W, height: TERMINAL_H };
  }
  const step = props.steps.find(s => s.id === node.id);
  return {
    width: NODE_WIDTH,
    height: step ? stepHeight(step) : NODE_HEIGHT_BASE,
  };
};

const applyLayout = (rawNodes, rawEdges) => {
  const g = new Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({
    rankdir: 'TB',
    nodesep: 72,
    ranksep: 100,
    marginx: 32,
    marginy: 32,
  });

  rawNodes.forEach(node => {
    const { width, height } = nodeSize(node);
    g.setNode(node.id, { width, height });
  });
  rawEdges.forEach(edge => {
    if (g.hasNode(edge.source) && g.hasNode(edge.target)) {
      g.setEdge(edge.source, edge.target);
    }
  });

  dagreLayout(g);

  return rawNodes.map(node => {
    const pos = g.node(node.id);
    const { width, height } = nodeSize(node);
    return {
      ...node,
      position: {
        x: (pos?.x || 0) - width / 2,
        y: (pos?.y || 0) - height / 2,
      },
    };
  });
};

const collectPositions = layoutNodes => {
  const next = {};
  layoutNodes.forEach(node => {
    next[node.id] = {
      x: node.position?.x || 0,
      y: node.position?.y || 0,
    };
  });
  return next;
};

const buildStepData = (step, index) => ({
  title: step.title || '',
  label: messagePreview(step),
  buttons: step.buttons || [],
  stepIndex: index,
  canRemove: props.steps.length > 1,
  brokenBranch: hasBrokenBranch(step),
  onRemove: idx => emit('removeStep', idx),
});

const buildRawGraph = () => {
  const rawNodes = props.steps.map((step, index) => ({
    id: step.id,
    type: 'step',
    position: { x: 0, y: 0 },
    selected: step.id === props.selectedStepId,
    data: buildStepData(step, index),
  }));

  const needsEnd = props.steps.some(step => {
    const buttons = filledButtons(step);
    if (buttons.length) {
      return buttons.some(btn => {
        const btnIndex = step.buttons.indexOf(btn);
        return branchTarget(step, btnIndex) === TERMINAL_END;
      });
    }
    return linearTarget(step) === TERMINAL_END;
  });

  const needsHandoff = props.steps.some(step => {
    const buttons = filledButtons(step);
    if (buttons.length) {
      return buttons.some(btn => {
        const btnIndex = step.buttons.indexOf(btn);
        return branchTarget(step, btnIndex) === TERMINAL_HANDOFF;
      });
    }
    return linearTarget(step) === TERMINAL_HANDOFF;
  });

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
  props.steps.forEach(step => {
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
          label: truncateLabel(btn.title),
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
      const target = linearTarget(step);
      rawEdges.push({
        id: `e-${step.id}-next-${target}`,
        source: step.id,
        sourceHandle: 'out',
        target,
        markerEnd: MarkerType.ArrowClosed,
        style: {
          stroke: hasBrokenNext(step) ? '#f5a524' : '#8da4ef',
        },
      });
    }
  });

  return { rawNodes, rawEdges };
};

const placeWithSavedOrDagre = (
  rawNodes,
  rawEdges,
  { forceDagre = false } = {}
) => {
  const saved = props.layoutPositions || {};
  const hasAnySaved = Object.keys(saved).length > 0;

  if (forceDagre || !hasAnySaved) {
    return applyLayout(rawNodes, rawEdges);
  }

  const missing = rawNodes.filter(n => !saved[n.id]);
  let dagrePositions = {};
  if (missing.length) {
    const laid = applyLayout(rawNodes, rawEdges);
    laid.forEach(n => {
      dagrePositions[n.id] = n.position;
    });
  }

  return rawNodes.map(node => {
    const fromSaved = saved[node.id];
    const fromDagre = dagrePositions[node.id];
    return {
      ...node,
      position: fromSaved
        ? { x: fromSaved.x, y: fromSaved.y }
        : fromDagre || { x: 0, y: 0 },
    };
  });
};

const rebuild = async ({ shouldFit = false, forceDagre = false } = {}) => {
  const { rawNodes, rawEdges } = buildRawGraph();
  const laid = placeWithSavedOrDagre(rawNodes, rawEdges, { forceDagre });
  nodes.value = laid;
  edges.value = rawEdges;

  const nextPositions = collectPositions(laid);
  const prev = props.layoutPositions || {};
  const changed =
    forceDagre ||
    Object.keys(nextPositions).some(
      id =>
        !prev[id] ||
        prev[id].x !== nextPositions[id].x ||
        prev[id].y !== nextPositions[id].y
    ) ||
    Object.keys(prev).some(id => !nextPositions[id]);
  if (changed) {
    emit('update:layoutPositions', nextPositions);
  }

  if (shouldFit) {
    await safeFitView();
  } else {
    await applyViewportIfNeeded();
  }
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
    const nextLabel = truncateLabel(title);
    if (!title || edge.label === nextLabel) return edge;
    return { ...edge, label: nextLabel };
  });
};

watch(
  structureKey,
  () => {
    const count = props.steps.length;
    const fit = isFirstLayout.value || count !== prevStepCount.value;
    prevStepCount.value = count;
    isFirstLayout.value = false;
    rebuild({
      shouldFit: fit && !Object.keys(props.layoutPositions || {}).length,
    });
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
  clearTimeout(viewportTimer);
});

const onNodeClick = ({ node }) => {
  if (node.type === 'step') emit('selectStep', node.id);
};

const onNodeDragStop = ({ node }) => {
  if (!node?.id) return;
  const next = {
    ...(props.layoutPositions || {}),
    [node.id]: {
      x: node.position?.x || 0,
      y: node.position?.y || 0,
    },
  };
  emit('update:layoutPositions', next);
};

const onMoveEnd = () => {
  clearTimeout(viewportTimer);
  viewportTimer = setTimeout(() => {
    try {
      const vp = getViewport();
      emit('update:viewport', {
        x: vp.x,
        y: vp.y,
        zoom: vp.zoom,
      });
    } catch {
      // vue-flow store not ready
    }
  }, 150);
};

const onConnect = connection => {
  if (!connection.source || !connection.target) return;
  if (connection.source === connection.target) return;
  if ([TERMINAL_END, TERMINAL_HANDOFF].includes(connection.source)) return;

  const handle = connection.sourceHandle;
  if (!handle || (handle !== 'out' && !/^btn-\d+$/.test(handle))) {
    useAlert(t('FLOWS.EDIT.CONNECT_HANDLE_REQUIRED'));
    return;
  }

  let target = connection.target;
  if (target === TERMINAL_END) target = 'end';
  else if (target === TERMINAL_HANDOFF) target = 'handoff';
  else if (!props.steps.some(s => s.id === target)) return;

  emit('connectBranch', {
    sourceId: connection.source,
    targetId: target,
    sourceHandle: handle,
  });
};

const onAddStep = () => {
  emit('addStep');
};

const onAutoLayout = async () => {
  await rebuild({ shouldFit: true, forceDagre: true });
};
</script>

<template>
  <div class="flex flex-col gap-2 h-full min-h-0 w-full">
    <div class="flex items-center justify-between gap-2 flex-shrink-0">
      <p class="m-0 text-xs text-n-slate-11">
        {{ t('FLOWS.EDIT.CANVAS_HINT') }}
      </p>
      <div class="flex items-center gap-2 flex-shrink-0">
        <NextButton
          slate
          faded
          sm
          icon="i-lucide-layout-dashboard"
          :label="t('FLOWS.EDIT.AUTO_LAYOUT')"
          @click="onAutoLayout"
        />
        <NextButton
          solid
          teal
          sm
          icon="i-lucide-plus-circle"
          :label="t('FLOWS.EDIT.ADD_BTN_TOOLTIP')"
          @click="onAddStep"
        />
      </div>
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
        snap-to-grid
        :snap-grid="[SNAP, SNAP]"
        :default-edge-options="{ type: 'smoothstep' }"
        :fit-view-on-init="!Object.keys(layoutPositions || {}).length"
        class="h-full w-full"
        @node-click="onNodeClick"
        @node-drag-stop="onNodeDragStop"
        @connect="onConnect"
        @move-end="onMoveEnd"
      >
        <Background pattern-color="#94a3b8" :gap="SNAP" :size="1" />
        <Controls position="bottom-left" />
        <MiniMap
          v-if="showMiniMap"
          pannable
          zoomable
          position="bottom-right"
          class="!bg-n-solid-2 !border-n-weak"
        />
      </VueFlow>
    </div>
  </div>
</template>
