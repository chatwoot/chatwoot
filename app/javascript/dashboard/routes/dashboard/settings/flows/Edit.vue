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
import FlowNodes from './FlowNodes.vue';
import FlowProperties from './FlowProperties.vue';

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

const name = ref('');
const description = ref('');
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

const emptyButtons = () => [
  { title: '', value: '' },
  { title: '', value: '' },
  { title: '', value: '' },
];

const ensureStepShape = step => {
  if (!step.buttons) step.buttons = emptyButtons();
  while (step.buttons.length < 3) step.buttons.push({ title: '', value: '' });
  if (!step.branches) step.branches = {};
  if (!step.actions?.length) step.actions = [emptyAction()];
  return step;
};

const addStep = () => {
  const step = ensureStepShape({
    id: newId(),
    actions: [emptyAction()],
    buttons: emptyButtons(),
    branches: {},
  });
  steps.value.push(step);
  selectedStepId.value = step.id;
};

const addActionToStep = step => {
  step.actions.push({
    action_name: 'add_label',
    action_params: [],
  });
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
  if (selectedStepId.value === removed.id) {
    selectedStepId.value = steps.value[Math.max(0, index - 1)]?.id || null;
  }
};

const stepLabel = step => {
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
    label: `${t('FLOWS.EDIT.STEP_N', { n: i + 1 })}: ${stepLabel(s)}`,
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

const branchTargetFor = (step, label, btnIndex) => {
  // Prefer index-keyed branches (editor); fall back to label keys (legacy)
  return step.branches?.[btnIndex] ?? step.branches?.[label];
};

const buildGraph = () => {
  const nodes = [];
  const edges = [];

  steps.value.forEach((step, index) => {
    const sendId = step.id;
    const buttons = (step.buttons || []).filter(b => b.title).slice(0, 3);

    nodes.push({
      id: sendId,
      type: 'actions',
      data: {
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
              data: { reason: t('FLOWS.EDIT.HANDOFF_REASON', { label }) },
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
      const next = steps.value[index + 1];
      if (next) {
        edges.push({ from: sendId, to: next.id });
      } else {
        const endId = `end_${sendId}`;
        nodes.push({ id: endId, type: 'end', data: {} });
        edges.push({ from: sendId, to: endId });
      }
    }
  });

  return {
    entry_node_id: steps.value[0]?.id,
    nodes,
    edges,
  };
};

const nodeToStep = (node, graph) => {
  const buttons = (node.data?.buttons || []).map(b => ({
    title: b.title,
    value: b.value,
  }));
  while (buttons.length < 3) buttons.push({ title: '', value: '' });

  const branches = {};
  (graph.edges || [])
    .filter(e => e.from === `${node.id}_wait`)
    .forEach(e => {
      const label = e.when?.match_label;
      if (!label) return;
      const btnIndex = buttons.findIndex(b => (b.value || b.title) === label);
      if (btnIndex < 0) return;

      const targetNode = (graph.nodes || []).find(n => n.id === e.to);
      if (!targetNode) return;
      if (targetNode.type === 'end') branches[btnIndex] = 'end';
      else if (targetNode.type === 'handoff') branches[btnIndex] = 'handoff';
      else if (['actions', 'send_message'].includes(targetNode.type)) {
        branches[btnIndex] = e.to;
      }
    });

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
    actions,
    buttons,
    branches,
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
    active.value = flow.active;
    exitPolicy.value = {
      ...exitPolicy.value,
      ...(flow.exit_policy || {}),
    };
    // Deep-merge per-event defaults so missing keys stay editable
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
  <div class="flex flex-col gap-6 mb-8 max-w-7xl mx-auto h-full w-full !px-6">
    <woot-loading-state v-if="loading" :message="t('FLOWS.EDIT.LOADING')" />
    <div v-else class="flex flex-col w-full h-auto lg:flex-row lg:h-full">
      <div
        class="flex-1 w-full h-full max-h-full ltr:pl-12 ltr:pr-6 rtl:pl-6 rtl:pr-12 py-4 overflow-y-auto lg:w-auto flow-gradient-radial dark:flow-dark-gradient-radial flow-gradient-radial-size"
      >
        <FlowNodes
          :steps="steps"
          :selected-step-id="selectedStepId"
          :flow-action-types="flowActionTypes"
          :get-action-dropdown-values="getActionDropdownValues"
          @select-step="selectedStepId = $event"
          @add-step="addStep"
          @remove-step="removeStep"
          @add-action="addActionToStep"
          @remove-action="removeActionFromStep"
          @reset-action="resetAction"
        />
      </div>

      <div class="w-full lg:w-1/3 pb-4">
        <FlowProperties
          :name="name"
          :description="description"
          :active="active"
          :exit-policy="exitPolicy"
          :selected-step="selectedStep"
          :selected-step-index="selectedStepIndex"
          :step-targets="stepTargets"
          :agents="agents"
          :teams="teams"
          :saving="saving || uiFlags.isCreating || uiFlags.isUpdating"
          @update:name="name = $event"
          @update:description="description = $event"
          @update:active="active = $event"
          @submit="save"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
@tailwind components;

@layer components {
  .flow-gradient-radial {
    background-image: radial-gradient(#ebf0f5 1.2px, transparent 0);
  }

  .flow-dark-gradient-radial {
    background-image: radial-gradient(#293f51 1.2px, transparent 0);
  }

  .flow-gradient-radial-size {
    background-size: 1rem 1rem;
  }
}
</style>
