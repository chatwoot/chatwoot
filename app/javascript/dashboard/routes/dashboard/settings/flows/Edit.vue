<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import useAutomationValues from 'dashboard/composables/useAutomationValues';
import { useStatusLabel } from 'dashboard/composables/useStatusLabel';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import { FLOW_ACTION_TYPES } from './constants';
import FlowCanvas from './FlowCanvas.vue';
import FlowStepInspector from './FlowStepInspector.vue';
import FlowHeader from './FlowHeader.vue';
import FlowFooter from './FlowFooter.vue';
import FlowOverview from './FlowOverview.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const getters = useStoreGetters();
const { getActionDropdownValues } = useAutomationValues();
const { getResolveConversationPhrase } = useStatusLabel();

const isNew = computed(() => route.name === 'flows_new');
const uiFlags = computed(() => getters['flows/getUIFlags'].value);
const agents = computed(() => getters['agents/getAgents'].value || []);
const teams = computed(() => getters['teams/getTeams'].value || []);
const loading = ref(!isNew.value);
const saving = ref(false);
const selectedStepId = ref(null);
const exitDialogRef = ref(null);
const overviewDialogRef = ref(null);
const layoutPositions = ref({});
const canvasViewport = ref({ x: 0, y: 0, zoom: 1 });

const name = ref('');
const description = ref('');
const category = ref('');
const active = ref(true);
const steps = ref([]);
const exitPolicy = ref({
  on_complete: { status: 'resolved', assignee_mode: 'none' },
  on_handoff: {
    status: 'open',
    assignee_mode: 'unassigned',
    private_note: true,
  },
  on_fail: { status: 'open', assignee_mode: 'unassigned', private_note: true },
  on_human_break: { status: 'open', assignee_mode: 'keep', private_note: true },
});

const flowActionTypes = computed(() =>
  FLOW_ACTION_TYPES.map(type => ({
    ...type,
    label:
      type.label === 'RESOLVE_CONVERSATION'
        ? getResolveConversationPhrase()
        : t(`AUTOMATION.ACTIONS.${type.label}`),
  }))
);

const selectedStep = computed(
  () => steps.value.find(s => s.id === selectedStepId.value) || null
);
const selectedStepIndex = computed(() =>
  steps.value.findIndex(s => s.id === selectedStepId.value)
);

const newId = () => `n${Date.now()}_${Math.floor(Math.random() * 1000)}`;

const emptyAction = () => ({
  action_name: 'send_message',
  action_params: [],
  delivery: { delay_seconds: 3, mark_read_and_typing: true },
});

const ensureStepShape = step => {
  if (step.title === undefined) step.title = '';
  if (!Array.isArray(step.buttons)) step.buttons = [];
  if (!step.branches) step.branches = {};
  if (step.next === undefined) step.next = 'end';
  if (!step.actions?.length) step.actions = [emptyAction()];
  return step;
};

const addStep = () => {
  const step = ensureStepShape({
    id: newId(),
    title: '',
    actions: [emptyAction()],
    buttons: [],
    branches: {},
    next: 'end',
  });
  steps.value.push(step);
  selectedStepId.value = step.id;
};

const addActionToStep = step => {
  const used = new Set((step.actions || []).map(a => a.action_name));
  const nextType = flowActionTypes.value.find(type => !used.has(type.key));
  if (!nextType) return;

  const action = {
    action_name: nextType.key,
    action_params: [],
  };
  if (nextType.key === 'send_message') {
    action.delivery = { delay_seconds: 3, mark_read_and_typing: true };
  }
  step.actions.push(action);
};

const removeActionFromStep = (step, actionIndex) => {
  if (step.actions.length <= 1) return;
  step.actions.splice(actionIndex, 1);
};

const resetAction = (step, actionIndex) => {
  step.actions[actionIndex] = {
    ...step.actions[actionIndex],
    action_params: [],
    delivery: undefined,
  };
};

const removeStep = index => {
  if (steps.value.length === 1) return;
  const removed = steps.value[index];
  steps.value.splice(index, 1);
  steps.value.forEach(step => {
    if (step.next === removed.id) step.next = 'end';
    Object.keys(step.branches || {}).forEach(key => {
      if (step.branches[key] === removed.id) step.branches[key] = 'end';
    });
  });
  if (layoutPositions.value[removed.id]) {
    const next = { ...layoutPositions.value };
    delete next[removed.id];
    layoutPositions.value = next;
  }
  if (selectedStepId.value === removed.id) {
    selectedStepId.value = steps.value[Math.max(0, index - 1)]?.id || null;
  }
};

const connectBranch = ({ sourceId, targetId, sourceHandle }) => {
  const step = steps.value.find(s => s.id === sourceId);
  if (!step) return;
  ensureStepShape(step);

  const handleMatch = sourceHandle?.match(/^btn-(\d+)$/);
  if (handleMatch) {
    const btnIndex = Number(handleMatch[1]);
    if (!step.branches) step.branches = {};
    step.branches[btnIndex] = targetId;
    return;
  }

  // Linear "out" handle only — never guess a button branch.
  if (sourceHandle !== 'out') return;

  const buttons = (step.buttons || []).filter(b => (b.title || '').trim());
  if (buttons.length) return;

  step.next = targetId;
};

const stepPreview = step => {
  if ((step.title || '').trim()) return step.title.trim();
  const send = (step.actions || []).find(a => a.action_name === 'send_message');
  if (send) {
    const content = Array.isArray(send.action_params)
      ? send.action_params[0]
      : send.action_params;
    if (typeof content === 'string' && content.trim()) {
      return content.slice(0, 40);
    }
  }
  const first = step.actions?.[0]?.action_name;
  const type = FLOW_ACTION_TYPES.find(a => a.key === first);
  return type ? t(`AUTOMATION.ACTIONS.${type.label}`) : step.id;
};

const stepTargets = computed(() => [
  { id: 'end', label: t('FLOWS.EDIT.BRANCH_END') },
  { id: 'handoff', label: t('FLOWS.EDIT.BRANCH_HANDOFF') },
  ...steps.value.map((s, i) => ({
    id: s.id,
    label: `${t('FLOWS.EDIT.STEP_N', { n: i + 1 })}: ${stepPreview(s)}`,
  })),
]);

const formatActionForEditor = action => {
  const inputType = flowActionTypes.value.find(
    item => item.key === action.action_name
  )?.inputType;
  let actionParams = action.action_params || [];
  const hasParams = Array.isArray(actionParams)
    ? actionParams.length > 0
    : actionParams &&
      typeof actionParams === 'object' &&
      Object.keys(actionParams).length > 0;

  if (hasParams) {
    if (inputType === 'multi_select' || inputType === 'search_select') {
      actionParams = getActionDropdownValues(action.action_name).filter(item =>
        [...action.action_params].includes(item.id)
      );
    } else if (inputType === 'team_message') {
      const raw = Array.isArray(action.action_params)
        ? action.action_params[0]
        : action.action_params;
      actionParams = {
        team_ids: getActionDropdownValues('send_email_to_team').filter(item =>
          [...(raw?.team_ids || [])].includes(item.id)
        ),
        message: raw?.message || '',
      };
    } else if (inputType === 'custom_attribute') {
      actionParams = Array.isArray(action.action_params)
        ? action.action_params[0] || {}
        : action.action_params || {};
    }
  }

  return {
    action_name: action.action_name,
    action_params: actionParams,
    ...(action.delivery ? { delivery: action.delivery } : {}),
  };
};

const serializeStepActions = actions => {
  const generated = actionQueryGenerator(actions);
  return generated.map((serialized, i) => {
    const original = actions[i] || {};
    const out = {
      action_name: serialized.action_name,
      action_params: serialized.action_params,
    };
    if (original.delivery) out.delivery = original.delivery;
    return out;
  });
};

const branchTargetFor = (step, label, btnIndex) =>
  step.branches?.[btnIndex] ?? step.branches?.[label];

const buildGraph = () => {
  const nodes = [];
  const edges = [];

  steps.value.forEach(step => {
    const sendId = step.id;
    const buttons = (step.buttons || []).filter(b => b.title).slice(0, 3);

    nodes.push({
      id: sendId,
      type: 'actions',
      data: {
        ...(step.title?.trim() ? { title: step.title.trim() } : {}),
        actions: serializeStepActions(step.actions || []),
        buttons: buttons.map(b => ({
          title: b.title,
          value: b.value || b.title,
        })),
      },
    });

    if (buttons.length) {
      const waitId = `${sendId}_wait`;
      nodes.push({
        id: waitId,
        type: 'wait_response',
        data: {
          match: buttons.map(b => ({
            label: b.value || b.title,
            pattern: `^${(b.value || b.title).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`,
            value: b.value || b.title,
          })),
        },
      });
      edges.push({ from: sendId, to: waitId });

      buttons.forEach(b => {
        const label = b.value || b.title;
        const reasonLabel = (b.title || '').trim() || label;
        const btnIndex = (step.buttons || []).indexOf(b);
        const targetKey = branchTargetFor(step, label, btnIndex);
        let toId = targetKey;
        if (!toId || toId === 'end') {
          toId = `end_${sendId}_${label}`;
          if (!nodes.find(n => n.id === toId)) {
            nodes.push({ id: toId, type: 'end', data: {} });
          }
        } else if (toId === 'handoff') {
          toId = `handoff_${sendId}_${label}`;
          if (!nodes.find(n => n.id === toId)) {
            nodes.push({
              id: toId,
              type: 'handoff',
              data: {
                reason: t('FLOWS.EDIT.HANDOFF_REASON', { label: reasonLabel }),
              },
            });
          }
        }
        edges.push({
          from: waitId,
          to: toId,
          when: { match_label: label },
        });
      });
    } else {
      const targetKey = step.next || 'end';
      let toId = targetKey;
      if (targetKey === 'end') {
        toId = `end_${sendId}`;
        if (!nodes.find(n => n.id === toId)) {
          nodes.push({ id: toId, type: 'end', data: {} });
        }
      } else if (targetKey === 'handoff') {
        toId = `handoff_${sendId}`;
        if (!nodes.find(n => n.id === toId)) {
          nodes.push({
            id: toId,
            type: 'handoff',
            data: {
              reason: step.title?.trim() || t('FLOWS.EDIT.BRANCH_HANDOFF'),
            },
          });
        }
      }
      edges.push({ from: sendId, to: toId });
    }
  });

  return {
    entry_node_id: steps.value[0]?.id,
    nodes,
    edges,
    ui: {
      positions: { ...(layoutPositions.value || {}) },
      viewport: {
        x: canvasViewport.value?.x || 0,
        y: canvasViewport.value?.y || 0,
        zoom: canvasViewport.value?.zoom || 1,
      },
    },
  };
};

const resolveGraphTarget = (targetId, graph) => {
  const targetNode = (graph.nodes || []).find(n => n.id === targetId);
  if (!targetNode) return null;
  if (targetNode.type === 'end') return 'end';
  if (targetNode.type === 'handoff') return 'handoff';
  if (['actions', 'send_message'].includes(targetNode.type)) return targetId;
  return null;
};

const nodeToStep = (node, graph) => {
  const buttons = (node.data?.buttons || []).map(b => ({
    title: b.title,
    value: b.value,
  }));

  const branches = {};
  (graph.edges || [])
    .filter(e => e.from === `${node.id}_wait`)
    .forEach(e => {
      const label = e.when?.match_label;
      if (!label) return;
      const btnIndex = buttons.findIndex(b => (b.value || b.title) === label);
      if (btnIndex < 0) return;

      const resolved = resolveGraphTarget(e.to, graph);
      if (resolved) branches[btnIndex] = resolved;
    });

  let next = 'end';
  const linearEdge = (graph.edges || []).find(
    e => e.from === node.id && !e.when
  );
  if (linearEdge) {
    const resolved = resolveGraphTarget(linearEdge.to, graph);
    if (resolved) next = resolved;
  }

  let actions = [];
  if (node.type === 'actions') {
    actions = (node.data?.actions || []).map(formatActionForEditor);
  } else if (node.type === 'send_message') {
    actions = [
      formatActionForEditor({
        action_name: 'send_message',
        action_params: [node.data?.content || ''],
        delivery: {
          delay_seconds: node.data?.delay_seconds || 3,
          mark_read_and_typing: true,
        },
      }),
    ];
  }

  if (!actions.length) actions = [emptyAction()];

  return ensureStepShape({
    id: node.id,
    title: node.data?.title || '',
    actions,
    buttons,
    branches,
    next,
  });
};

const loadFlow = async () => {
  if (isNew.value) {
    addStep();
    loading.value = false;
    return;
  }
  loading.value = true;
  try {
    const flow = await store.dispatch('flows/show', route.params.flowId);
    name.value = flow.name;
    description.value = flow.description || '';
    category.value = flow.category || '';
    active.value = flow.active;
    exitPolicy.value = {
      ...exitPolicy.value,
      ...(flow.exit_policy || {}),
    };
    ['on_complete', 'on_handoff', 'on_fail', 'on_human_break'].forEach(key => {
      exitPolicy.value[key] = {
        status: 'open',
        assignee_mode: 'keep',
        ...exitPolicy.value[key],
      };
    });

    const graph = flow.graph || {};
    const stepNodes = (graph.nodes || []).filter(n =>
      ['actions', 'send_message'].includes(n.type)
    );
    steps.value = stepNodes.map(node => nodeToStep(node, graph));
    const ui = graph.ui || {};
    layoutPositions.value = { ...(ui.positions || {}) };
    canvasViewport.value = {
      x: ui.viewport?.x || 0,
      y: ui.viewport?.y || 0,
      zoom: ui.viewport?.zoom || 1,
    };
    if (!steps.value.length) addStep();
    else selectedStepId.value = steps.value[0].id;
  } finally {
    loading.value = false;
  }
};

const save = async () => {
  if (!name.value.trim() || !steps.value.length) {
    useAlert(t('FLOWS.EDIT.VALIDATION'));
    return;
  }
  saving.value = true;
  const payload = {
    name: name.value.trim(),
    description: description.value,
    category: category.value.trim() || null,
    active: active.value,
    graph: buildGraph(),
    exit_policy: exitPolicy.value,
  };
  try {
    if (isNew.value) {
      await store.dispatch('flows/create', payload);
      useAlert(t('FLOWS.ADD.API.SUCCESS_MESSAGE'));
      router.push({ name: 'flows_index' });
    } else {
      await store.dispatch('flows/update', {
        id: route.params.flowId,
        ...payload,
      });
      useAlert(t('FLOWS.EDIT.API.SUCCESS_MESSAGE'));
      router.push({ name: 'flows_index' });
    }
  } catch (e) {
    useAlert(t('FLOWS.EDIT.API.ERROR_MESSAGE'));
  } finally {
    saving.value = false;
  }
};

watch(selectedStep, step => {
  if (step) ensureStepShape(step);
});

onMounted(async () => {
  await Promise.all([
    store.dispatch('agents/get'),
    store.dispatch('teams/get'),
    store.dispatch('labels/get'),
    store.dispatch('attributes/get'),
  ]);
  await loadFlow();
});
</script>

<template>
  <div class="flex flex-col h-full w-full min-h-0">
    <woot-loading-state v-if="loading" :message="t('FLOWS.EDIT.LOADING')" />
    <template v-else>
      <FlowHeader
        :name="name"
        :description="description"
        :category="category"
        :saving="saving || uiFlags.isCreating || uiFlags.isUpdating"
        @update:name="name = $event"
        @update:description="description = $event"
        @update:category="category = $event"
        @open-exit="exitDialogRef?.open()"
        @open-overview="overviewDialogRef?.open()"
        @submit="save"
      />

      <div
        class="flex flex-col-reverse lg:flex-row flex-1 min-h-0 gap-3 px-4 py-3 overflow-auto lg:overflow-hidden"
      >
        <div
          class="w-full lg:w-[28rem] xl:w-[32rem] flex-shrink-0 min-h-[20rem] lg:min-h-0 lg:h-full"
        >
          <FlowStepInspector
            :selected-step="selectedStep"
            :selected-step-index="selectedStepIndex"
            :step-targets="stepTargets"
            :flow-action-types="flowActionTypes"
            :get-action-dropdown-values="getActionDropdownValues"
            @add-action="addActionToStep"
            @remove-action="removeActionFromStep"
            @reset-action="resetAction"
          />
        </div>
        <div class="flex-1 min-w-0 min-h-[50vh] lg:min-h-0">
          <FlowCanvas
            :steps="steps"
            :selected-step-id="selectedStepId"
            :layout-positions="layoutPositions"
            :viewport="canvasViewport"
            @select-step="selectedStepId = $event"
            @add-step="addStep"
            @remove-step="removeStep"
            @connect-branch="connectBranch"
            @update:layout-positions="layoutPositions = $event"
            @update:viewport="canvasViewport = $event"
          />
        </div>
      </div>

      <Dialog
        ref="overviewDialogRef"
        type="edit"
        width="2xl"
        overflow-y-auto
        :title="t('FLOWS.EDIT.OVERVIEW_TITLE')"
        :confirm-button-label="t('FLOWS.EXIT.DONE')"
        :show-cancel-button="false"
        @confirm="overviewDialogRef?.close()"
      >
        <FlowOverview
          :steps="steps"
          :step-targets="stepTargets"
          :flow-action-types="flowActionTypes"
        />
      </Dialog>

      <Dialog
        ref="exitDialogRef"
        type="edit"
        width="3xl"
        overflow-y-auto
        :title="t('FLOWS.EXIT.TITLE')"
        :confirm-button-label="t('FLOWS.EXIT.DONE')"
        :show-cancel-button="false"
        @confirm="exitDialogRef?.close()"
      >
        <FlowFooter :exit-policy="exitPolicy" :agents="agents" :teams="teams" />
      </Dialog>
    </template>
  </div>
</template>
