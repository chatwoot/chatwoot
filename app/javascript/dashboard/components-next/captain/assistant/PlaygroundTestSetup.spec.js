import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import AddNewRulesInput from 'dashboard/components-next/captain/assistant/AddNewRulesInput.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import PlaygroundTestSetup from './PlaygroundTestSetup.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params = {}) =>
      params.count === undefined ? key : `${key} (${params.count})`,
  }),
}));

const buildSession = overrides => ({
  isAdmin: false,
  isInitializing: false,
  loadError: '',
  savedScenarios: [
    { id: 1, title: 'Enabled scenario', description: 'Enabled', enabled: true },
    {
      id: 2,
      title: 'Disabled scenario',
      description: 'Disabled',
      enabled: false,
    },
  ],
  includedScenarioIds: [1],
  temporaryScenarios: [],
  savedGuidelines: [
    { key: 'guideline-1', content: 'Be concise', included: true },
  ],
  temporaryGuidelines: [],
  savedGuardrails: [
    { key: 'guardrail-1', content: 'Protect secrets', included: true },
  ],
  temporaryGuardrails: [],
  knowledgeText: '',
  isKnowledgeIncluded: true,
  isSavingKnowledge: false,
  isRuleTypeSaving: vi.fn(() => false),
  knowledgeStats: { documents: 12, faqs: 48 },
  toggleScenario: vi.fn(),
  addTemporaryScenario: vi.fn(),
  removeTemporaryScenario: vi.fn(),
  scenarioIsValid: vi.fn(() => true),
  saveTemporaryScenario: vi.fn(),
  addTemporaryRule: vi.fn(),
  removeTemporaryRule: vi.fn(),
  saveTemporaryRule: vi.fn(),
  setKnowledgeText: vi.fn(),
  setKnowledgeIncluded: vi.fn(),
  saveKnowledgeAsDocument: vi.fn(),
  ...overrides,
});

const mountSetup = (overrides = {}) =>
  shallowMount(PlaygroundTestSetup, {
    props: { session: buildSession(overrides) },
    global: {
      stubs: { Accordion: false },
    },
  });

const selectTab = async (wrapper, id) => {
  wrapper.findComponent(TabBar).vm.$emit('tabChanged', { id });
  await nextTick();
};

describe('PlaygroundTestSetup', () => {
  it('uses one tabbed content area without counts or a scroll container', () => {
    const wrapper = mountSetup();
    const tabs = wrapper.findComponent(TabBar).props('tabs');

    expect(tabs.map(tab => tab.id)).toEqual([
      'knowledge',
      'scenarios',
      'guidelines',
      'guardrails',
    ]);
    expect(tabs.every(tab => tab.count === undefined)).toBe(true);
    expect(
      wrapper.get('[data-testid="playground-setup-tabs"]').classes()
    ).not.toContain('overflow-x-auto');
    expect(wrapper.findComponent(TabBar).classes()).toContain('!w-full');
    expect(wrapper.findAllComponents(Accordion)).toHaveLength(0);
    expect(wrapper.text()).not.toContain('Be concise');
    expect(wrapper.text()).not.toContain('Protect secrets');
  });

  it('keeps saved scenarios collapsed until requested', async () => {
    const wrapper = mountSetup();
    await selectTab(wrapper, 'scenarios');
    const savedScenarios = wrapper.findComponent(Accordion);

    expect(savedScenarios.props('title')).toBe(
      'CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.SAVED_SUMMARY (2)'
    );
    expect(wrapper.text()).not.toContain('Disabled scenario');

    await savedScenarios.get('button').trigger('click');

    expect(wrapper.text()).toContain('Disabled scenario');
  });

  it('shows only the total count in each saved section header', async () => {
    const wrapper = mountSetup();

    await selectTab(wrapper, 'guidelines');
    expect(wrapper.findComponent(Accordion).props('title')).toBe(
      'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.SAVED_SUMMARY (1)'
    );

    await selectTab(wrapper, 'guardrails');
    expect(wrapper.findComponent(Accordion).props('title')).toBe(
      'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.SAVED_SUMMARY (1)'
    );
  });

  it('prioritizes temporary actions and keeps persistence secondary', async () => {
    const wrapper = mountSetup({
      isAdmin: true,
      temporaryScenarios: [
        {
          clientId: 'temporary-1',
          title: 'Refund request',
          description: 'Handle refunds',
          instruction: 'Follow the refund policy',
          included: true,
          isSaving: false,
        },
      ],
    });
    await selectTab(wrapper, 'scenarios');
    const labels = wrapper
      .findAllComponents(Button)
      .map(button => button.props('label'));

    expect(labels).toContain(
      'CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.ADD_PERMANENTLY'
    );
    expect(labels).not.toContain('CAPTAIN.PLAYGROUND.SETUP.SAVE_TO_SCENARIOS');
    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.SETUP.INCLUDE_IN_TEST'
    );
  });

  it('collapses and expands temporary scenarios', async () => {
    const wrapper = mountSetup({
      temporaryScenarios: [
        {
          clientId: 'temporary-1',
          title: 'Refund request',
          description: 'Handle refunds',
          instruction: 'Follow the refund policy',
          included: true,
          isSaving: false,
        },
      ],
    });
    await selectTab(wrapper, 'scenarios');

    expect(wrapper.findComponent(InlineInput).props('modelValue')).toBe(
      'Refund request'
    );
    expect(wrapper.find('#temporary-scenario-temporary-1').exists()).toBe(true);
    const collapseButton = wrapper
      .findAllComponents(Button)
      .find(
        button =>
          button.attributes('aria-label') ===
          'CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.COLLAPSE'
      );

    collapseButton.vm.$emit('click');
    await nextTick();

    expect(wrapper.find('#temporary-scenario-temporary-1').exists()).toBe(
      false
    );
    expect(wrapper.findComponent(InlineInput).props('modelValue')).toBe(
      'Refund request'
    );
    expect(
      wrapper
        .findAllComponents(Button)
        .some(
          button =>
            button.attributes('aria-label') ===
            'CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.EXPAND'
        )
    ).toBe(true);
  });

  it('uses quick entry for knowledge, scenarios, and rules', async () => {
    const addTemporaryScenario = vi.fn();
    const addTemporaryRule = vi.fn();
    const setKnowledgeText = vi.fn();
    const wrapper = mountSetup({
      addTemporaryScenario,
      addTemporaryRule,
      setKnowledgeText,
    });

    let rulesInput = wrapper.findComponent(AddNewRulesInput);
    expect(rulesInput.props()).toMatchObject({
      placeholder: 'CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.COMPOSER_PLACEHOLDER',
      label: 'CAPTAIN.PLAYGROUND.SETUP.ADD_TO_TEST',
      maxLength: 10000,
    });
    rulesInput.vm.$emit('add', 'Refunds take five days');
    await nextTick();
    expect(setKnowledgeText).toHaveBeenCalledWith('Refunds take five days');
    expect(wrapper.findComponent(TextArea).exists()).toBe(true);

    await selectTab(wrapper, 'scenarios');
    rulesInput = wrapper.findComponent(AddNewRulesInput);
    expect(rulesInput.props()).toMatchObject({
      placeholder: 'CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.COMPOSER_PLACEHOLDER',
      label: 'CAPTAIN.PLAYGROUND.SETUP.ADD_TO_TEST',
    });
    rulesInput.vm.$emit('add', 'Refund request');
    expect(addTemporaryScenario).toHaveBeenCalledWith('Refund request');

    await selectTab(wrapper, 'guidelines');
    rulesInput = wrapper.findComponent(AddNewRulesInput);
    expect(rulesInput.props()).toMatchObject({
      placeholder: 'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.COMPOSER_PLACEHOLDER',
      label: 'CAPTAIN.PLAYGROUND.SETUP.ADD_TO_TEST',
    });
    rulesInput.vm.$emit('add', 'Keep replies concise');
    expect(addTemporaryRule).toHaveBeenCalledWith(
      'guideline',
      'Keep replies concise'
    );

    await selectTab(wrapper, 'guardrails');
    rulesInput = wrapper.findComponent(AddNewRulesInput);
    expect(rulesInput.props()).toMatchObject({
      placeholder: 'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.COMPOSER_PLACEHOLDER',
      label: 'CAPTAIN.PLAYGROUND.SETUP.ADD_TO_TEST',
    });
    rulesInput.vm.$emit('add', 'Never expose passwords');
    expect(addTemporaryRule).toHaveBeenCalledWith(
      'guardrail',
      'Never expose passwords'
    );
  });

  it('shows permanent and inclusion actions beneath temporary rules', async () => {
    const wrapper = mountSetup({
      isAdmin: true,
      temporaryGuidelines: [
        {
          clientId: 'guideline-1',
          content: 'Keep replies concise',
          included: true,
          isSaving: false,
        },
      ],
      temporaryGuardrails: [
        {
          clientId: 'guardrail-1',
          content: 'Never expose passwords',
          included: true,
          isSaving: false,
        },
      ],
    });

    await selectTab(wrapper, 'guidelines');
    expect(
      wrapper
        .findAllComponents(Button)
        .some(
          button =>
            button.props('label') ===
            'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.ADD_PERMANENTLY'
        )
    ).toBe(true);
    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.SETUP.INCLUDE_IN_TEST'
    );

    await selectTab(wrapper, 'guardrails');
    expect(
      wrapper
        .findAllComponents(Button)
        .some(
          button =>
            button.props('label') ===
            'CAPTAIN.PLAYGROUND.SETUP.GUARDRAILS.ADD_PERMANENTLY'
        )
    ).toBe(true);
    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.SETUP.INCLUDE_IN_TEST'
    );
  });

  it('disables same-type persistence actions while a rule is being saved', async () => {
    const wrapper = mountSetup({
      isAdmin: true,
      isRuleTypeSaving: type => type === 'guideline',
      temporaryGuidelines: [
        {
          clientId: 'guideline-1',
          content: 'Keep replies concise',
          included: true,
          isSaving: true,
        },
      ],
    });

    await selectTab(wrapper, 'guidelines');
    const saveButton = wrapper
      .findAllComponents(Button)
      .find(
        button =>
          button.props('label') ===
          'CAPTAIN.PLAYGROUND.SETUP.GUIDELINES.ADD_PERMANENTLY'
      );

    expect(saveButton.attributes('disabled')).toBe('true');
    expect(saveButton.props('isLoading')).toBe(true);
  });

  it('hides persisted actions from non-administrators', async () => {
    const wrapper = mountSetup({
      temporaryScenarios: [
        {
          clientId: 'temporary-1',
          title: 'Refund request',
          description: 'Handle refunds',
          instruction: 'Follow policy',
          included: true,
          isSaving: false,
        },
      ],
    });
    await selectTab(wrapper, 'scenarios');
    const labels = wrapper
      .findAllComponents(Button)
      .map(button => button.props('label'));

    expect(labels).not.toContain(
      'CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.ADD_PERMANENTLY'
    );
  });

  it('shows only aggregate saved knowledge before adding temporary content', () => {
    const wrapper = mountSetup();

    expect(wrapper.text()).toContain('12');
    expect(wrapper.text()).toContain('48');
    expect(wrapper.findComponent(TextArea).exists()).toBe(false);
    expect(wrapper.findComponent(AddNewRulesInput).exists()).toBe(true);
    expect(wrapper.findAllComponents(Accordion)).toHaveLength(0);
    expect(wrapper.text()).not.toContain('Enabled scenario');
  });

  it('saves temporary knowledge as a document', async () => {
    const saveKnowledgeAsDocument = vi.fn();
    const wrapper = mountSetup({
      isAdmin: true,
      knowledgeText: '# Refund policy',
      saveKnowledgeAsDocument,
    });
    const knowledgeField = wrapper.findComponent(TextArea);
    const saveButton = wrapper
      .findAllComponents(Button)
      .find(
        button =>
          button.props('label') ===
          'CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.ADD_PERMANENTLY'
      );

    expect(knowledgeField.props('placeholder')).toBe(
      'CAPTAIN.PLAYGROUND.SETUP.KNOWLEDGE.PLACEHOLDER'
    );
    saveButton.vm.$emit('click');
    await nextTick();

    expect(saveKnowledgeAsDocument).toHaveBeenCalledOnce();
  });

  it('clears every quick-entry draft when test setup is reset', async () => {
    const wrapper = mountSetup();

    wrapper
      .findComponent(AddNewRulesInput)
      .vm.$emit('update:modelValue', 'Temporary knowledge draft');
    await selectTab(wrapper, 'scenarios');
    wrapper
      .findComponent(AddNewRulesInput)
      .vm.$emit('update:modelValue', 'Temporary scenario draft');
    await selectTab(wrapper, 'guidelines');
    wrapper
      .findComponent(AddNewRulesInput)
      .vm.$emit('update:modelValue', 'Temporary guideline draft');
    await selectTab(wrapper, 'guardrails');
    wrapper
      .findComponent(AddNewRulesInput)
      .vm.$emit('update:modelValue', 'Temporary guardrail draft');
    await nextTick();

    const resetButton = wrapper
      .findAllComponents(Button)
      .find(
        button => button.props('label') === 'CAPTAIN.PLAYGROUND.SETUP.RESET'
      );
    resetButton.vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('reset')).toHaveLength(1);
    expect(wrapper.findComponent(AddNewRulesInput).props('modelValue')).toBe(
      ''
    );
    await selectTab(wrapper, 'scenarios');
    expect(wrapper.findComponent(AddNewRulesInput).props('modelValue')).toBe(
      ''
    );
    await selectTab(wrapper, 'guidelines');
    expect(wrapper.findComponent(AddNewRulesInput).props('modelValue')).toBe(
      ''
    );
    await selectTab(wrapper, 'guardrails');
    expect(wrapper.findComponent(AddNewRulesInput).props('modelValue')).toBe(
      ''
    );
  });

  it('resets the active tab and emits reset separately', async () => {
    const wrapper = mountSetup();
    await selectTab(wrapper, 'guardrails');
    const resetButton = wrapper
      .findAllComponents(Button)
      .find(
        button => button.props('label') === 'CAPTAIN.PLAYGROUND.SETUP.RESET'
      );

    resetButton.vm.$emit('click');
    await nextTick();

    expect(wrapper.findComponent(TabBar).props('initialActiveTab')).toBe(0);
    expect(wrapper.emitted('reset')).toEqual([[]]);
  });

  it('does not reintroduce customer or conversation filters', () => {
    const wrapper = mountSetup();

    expect(wrapper.find('select').exists()).toBe(false);
    expect(wrapper.text()).not.toContain(
      'CAPTAIN.PLAYGROUND.SETUP.CONTEXT.TITLE'
    );
  });
});
