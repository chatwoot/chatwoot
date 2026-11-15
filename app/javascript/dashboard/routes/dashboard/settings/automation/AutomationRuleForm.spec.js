import { nextTick, reactive, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import AutomationRuleForm from './AutomationRuleForm.vue';
import AutomationInstantTrigger from './components/AutomationInstantTrigger.vue';
import AutomationMonitorSelect from './components/AutomationMonitorSelect.vue';
import AutomationRunTypeSelector from './components/AutomationRunTypeSelector.vue';
import AutomationWaitCondition from './components/AutomationWaitCondition.vue';
import MonitorsAPI from 'dashboard/api/monitors';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const featureState = vi.hoisted(() => ({
  enabled: new Set([
    'reports',
    'conversation_monitors',
    'automations',
    'delayed_automations',
    'captain_classifier',
  ]),
  cloud: { value: true },
}));

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    accountId: ref(1),
    isCloudFeatureEnabled: feature => featureState.enabled.has(feature),
    isOnChatwootCloud: featureState.cloud,
  }),
}));

vi.mock('dashboard/composables/useConfig', () => ({
  useConfig: () => ({ isEnterprise: false }),
}));

vi.mock('dashboard/api/monitors', () => ({
  default: { get: vi.fn() },
}));

vi.mock('dashboard/components-next/filter/operators', () => ({
  useOperators: () => ({ operators: { value: {} } }),
}));

const automationTypes = Object.fromEntries(
  [
    'conversation_created',
    'conversation_updated',
    'conversation_resolved',
    'message_created',
    'conversation_opened',
  ].map(event => [event, { conditions: [] }])
);

const captainAutomationTypes = {
  ...automationTypes,
  conversation_created: {
    conditions: [
      {
        key: 'captain_condition',
        name: 'CAPTAIN',
        inputType: 'long_text',
        placeholder: 'CAPTAIN',
        maxLength: 500,
        filterOperators: [{ value: 'detects', label: 'Detects' }],
      },
      {
        key: 'status',
        name: 'STATUS',
        inputType: 'multi_select',
        filterOperators: [{ value: 'equal_to', label: 'Equal to' }],
      },
    ],
  },
};

const triggerStub = {
  props: ['events', 'filterTypes'],
  template: '<div><slot /></div>',
  methods: {
    resetValidation: vi.fn(),
    validate: vi.fn(() => true),
  },
};

const waitConditionStub = {
  props: ['isSavedWait'],
  template: '<div />',
  methods: {
    resetValidation: vi.fn(),
    validate: vi.fn(() => true),
  },
};

const instantConditions = [
  {
    attribute_key: 'status',
    filter_operator: 'equal_to',
    values: 'open',
    query_operator: 'and',
    custom_attribute_type: '',
  },
];

const waitConditions = [
  {
    attribute_key: 'message_type',
    filter_operator: 'equal_to',
    values: 'outgoing',
    query_operator: 'and',
    custom_attribute_type: '',
  },
  {
    attribute_key: 'private_note',
    filter_operator: 'equal_to',
    values: false,
    query_operator: 'and',
    custom_attribute_type: '',
  },
  {
    attribute_key: 'priority',
    filter_operator: 'equal_to',
    values: 'high',
    query_operator: null,
    custom_attribute_type: '',
  },
];

const buildAutomation = ({ delayed = false } = {}) => ({
  name: 'Follow up',
  description: 'Follow up after a wait',
  event_name: delayed ? 'message_created' : 'conversation_created',
  execution_delay: delayed ? 60 : null,
  conditions: structuredClone(delayed ? waitConditions : instantConditions),
  actions: [{ action_name: 'assign_agent', action_params: [] }],
  files: [],
});

const panelOpen = vi.fn();

const mountComponent = ({ mode, automation, types = automationTypes }) =>
  shallowMount(AutomationRuleForm, {
    props: {
      mode,
      automation,
      automationTypes: types,
      getConditionDropdownValues: vi.fn(() => []),
      getActionDropdownValues: vi.fn(() => []),
      appendNewCondition: vi.fn(),
      appendNewAction: vi.fn(),
      removeFilter: vi.fn(),
      removeAction: vi.fn(),
      resetAction: vi.fn(),
      onEventChange: vi.fn(),
    },
    global: {
      stubs: {
        SidePanel: {
          template: '<div><slot /><slot name="footer" /></div>',
          methods: {
            open: panelOpen,
            close: vi.fn(),
          },
        },
        AutomationInstantTrigger: triggerStub,
        AutomationWaitCondition: waitConditionStub,
        WootInput: true,
      },
    },
  });

const selectRunType = async (wrapper, isDelayed) => {
  wrapper
    .findComponent(AutomationRunTypeSelector)
    .vm.$emit('update:modelValue', isDelayed);
  await nextTick();
};

describe('AutomationRuleForm', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    featureState.enabled = new Set([
      'reports',
      'conversation_monitors',
      'automations',
      'delayed_automations',
      'captain_classifier',
    ]);
    featureState.cloud.value = true;
    MonitorsAPI.get.mockResolvedValue({
      data: { payload: [{ id: 7, name: 'Refunds' }], meta: { total_count: 1 } },
    });
  });

  it('opens a rule whose conditions hold reactive dropdown options', async () => {
    const automation = buildAutomation();
    // Conditions hydrated from store-backed dropdowns (inboxes, agents, contacts) hold
    // reactive option objects rather than plain ones.
    automation.conditions[0].values = [reactive({ id: 1, name: 'Sales' })];
    const wrapper = mountComponent({ mode: 'edit', automation });

    wrapper.vm.open();
    await nextTick();

    expect(panelOpen).toHaveBeenCalled();
  });

  it('offers the Captain condition when the account has the classifier feature', () => {
    const wrapper = mountComponent({
      mode: 'create',
      automation: buildAutomation(),
      types: captainAutomationTypes,
    });

    const filterTypes = wrapper
      .findComponent(AutomationInstantTrigger)
      .props('filterTypes');
    expect(filterTypes.map(filter => filter.attributeKey)).toEqual([
      'captain_condition',
      'status',
    ]);
    expect(filterTypes[0].maxLength).toBe(500);
    expect(filterTypes[0].inputType).toBe('longText');
  });

  it('hides the Captain condition without the classifier feature', () => {
    featureState.enabled.delete('captain_classifier');
    const wrapper = mountComponent({
      mode: 'create',
      automation: buildAutomation(),
      types: captainAutomationTypes,
    });

    const keys = wrapper
      .findComponent(AutomationInstantTrigger)
      .props('filterTypes')
      .map(filter => filter.attributeKey);
    expect(keys).toEqual(['status']);
  });

  it('keeps a saved Captain condition renderable but not selectable without the classifier feature', () => {
    featureState.enabled.delete('captain_classifier');
    const automation = buildAutomation();
    automation.conditions = [
      {
        attribute_key: 'captain_condition',
        filter_operator: 'detects',
        values: 'the customer wants a refund',
        query_operator: 'and',
        custom_attribute_type: '',
      },
    ];
    const wrapper = mountComponent({
      mode: 'edit',
      automation,
      types: captainAutomationTypes,
    });

    const captain = wrapper
      .findComponent(AutomationInstantTrigger)
      .props('filterTypes')
      .find(filter => filter.attributeKey === 'captain_condition');
    expect(captain.disabled).toBe(true);
    expect(captain.filterOperators.map(operator => operator.value)).toEqual([
      'detects',
    ]);
  });

  it('restores unsaved wait conditions after switching a new rule to instant and back', async () => {
    const automation = buildAutomation();
    const wrapper = mountComponent({ mode: 'create', automation });
    wrapper.vm.open();
    await nextTick();

    await selectRunType(wrapper, true);
    automation.event_name = 'message_created';
    automation.conditions = structuredClone(waitConditions);

    await selectRunType(wrapper, false);
    expect(automation.event_name).toBe('conversation_created');
    expect(automation.conditions).toEqual(instantConditions);

    await selectRunType(wrapper, true);
    expect(automation.event_name).toBe('message_created');
    expect(automation.conditions).toEqual(waitConditions);
    expect(
      wrapper.findComponent(AutomationWaitCondition).props('isSavedWait')
    ).toBe(true);
  });

  it('restores saved wait conditions after editing the instant draft', async () => {
    const automation = buildAutomation({ delayed: true });
    const wrapper = mountComponent({ mode: 'edit', automation });
    wrapper.vm.open(60);
    await nextTick();

    await selectRunType(wrapper, false);
    automation.event_name = 'conversation_created';
    automation.conditions = structuredClone(instantConditions);

    await selectRunType(wrapper, true);
    expect(automation.event_name).toBe('message_created');
    expect(automation.conditions).toEqual(waitConditions);
    expect(
      wrapper.findComponent(AutomationWaitCondition).props('isSavedWait')
    ).toBe(true);
  });

  it('accepts a monitor match without extra conditions and loads live monitors', async () => {
    const automation = {
      ...buildAutomation(),
      event_name: 'monitor_matched',
      monitor_id: 7,
      conditions: [],
      actions: [{ action_name: 'resolve_conversation', action_params: [] }],
    };
    const wrapper = mountComponent({ mode: 'create', automation });
    wrapper.vm.open();
    await flushPromises();

    expect(MonitorsAPI.get).toHaveBeenCalledWith(
      { active: 'true', page: 1 },
      expect.any(AbortSignal)
    );
    expect(
      wrapper.findComponent(AutomationMonitorSelect).props('options')
    ).toEqual([{ id: 7, name: 'Refunds' }]);
  });

  it('hides the monitor event when reports is disabled and skips monitor loading', async () => {
    featureState.enabled.delete('reports');
    const wrapper = mountComponent({
      mode: 'create',
      automation: buildAutomation(),
    });
    wrapper.vm.open();
    await flushPromises();

    expect(
      wrapper
        .findComponent(AutomationInstantTrigger)
        .props('events')
        .some(event => event.key === 'monitor_matched')
    ).toBe(false);
    expect(MonitorsAPI.get).not.toHaveBeenCalled();
  });

  it('hides the monitor event on a community installation', async () => {
    featureState.cloud.value = false;
    const wrapper = mountComponent({
      mode: 'create',
      automation: buildAutomation(),
    });
    wrapper.vm.open();
    await flushPromises();

    expect(
      wrapper
        .findComponent(AutomationInstantTrigger)
        .props('events')
        .some(event => event.key === 'monitor_matched')
    ).toBe(false);
    expect(MonitorsAPI.get).not.toHaveBeenCalled();
  });
});
