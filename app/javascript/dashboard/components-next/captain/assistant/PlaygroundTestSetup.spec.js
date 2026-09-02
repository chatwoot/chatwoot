import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import Accordion from 'dashboard/components-next/Accordion/Accordion.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import PlaygroundTestSetup from './PlaygroundTestSetup.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
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
  incrementFaqCount: vi.fn(),
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
  it('uses one tabbed content area with saved counts', () => {
    const wrapper = mountSetup();
    const tabs = wrapper.findComponent(TabBar).props('tabs');

    expect(tabs.map(tab => [tab.id, tab.count])).toEqual([
      ['scenarios', 2],
      ['guidelines', 1],
      ['guardrails', 1],
      ['knowledge', 60],
    ]);
    expect(wrapper.findAllComponents(Accordion)).toHaveLength(1);
    expect(wrapper.text()).not.toContain('Be concise');
    expect(wrapper.text()).not.toContain('Protect secrets');
  });

  it('keeps saved scenarios collapsed until requested', async () => {
    const wrapper = mountSetup();
    const savedScenarios = wrapper.findComponent(Accordion);

    expect(wrapper.text()).not.toContain('Disabled scenario');

    await savedScenarios.get('button').trigger('click');

    expect(wrapper.text()).toContain('Disabled scenario');
  });

  it('prioritizes temporary actions and keeps persistence secondary', () => {
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
    const labels = wrapper
      .findAllComponents(Button)
      .map(button => button.props('label'));

    expect(labels).toContain('CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.ADD_AS_SAVED');
    expect(labels).not.toContain('CAPTAIN.PLAYGROUND.SETUP.SAVE_TO_SCENARIOS');
    expect(wrapper.text()).toContain(
      'CAPTAIN.PLAYGROUND.SETUP.INCLUDE_IN_TEST'
    );
  });

  it('hides persisted actions from non-administrators', () => {
    const labels = mountSetup({
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
    })
      .findAllComponents(Button)
      .map(button => button.props('label'));

    expect(labels).not.toContain(
      'CAPTAIN.PLAYGROUND.SETUP.SCENARIOS.ADD_AS_SAVED'
    );
  });

  it('shows only aggregate saved knowledge and the temporary field', async () => {
    const wrapper = mountSetup();

    await selectTab(wrapper, 'knowledge');

    const knowledge = wrapper.findComponent(TextArea);
    expect(knowledge.props('maxLength')).toBe(10000);
    expect(wrapper.text()).toContain('12');
    expect(wrapper.text()).toContain('48');
    expect(wrapper.findAllComponents(Accordion)).toHaveLength(0);
    expect(wrapper.text()).not.toContain('Enabled scenario');
  });

  it('resets the active tab and emits reset separately', async () => {
    const wrapper = mountSetup();
    await selectTab(wrapper, 'knowledge');
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
