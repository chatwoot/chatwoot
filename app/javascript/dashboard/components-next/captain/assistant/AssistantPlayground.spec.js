import { computed, nextTick, reactive, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import AssistantPlayground from './AssistantPlayground.vue';

const mocks = vi.hoisted(() => ({
  playground: vi.fn(),
  initialize: vi.fn(),
  reset: vi.fn(),
  isFeatureFlagEnabled: vi.fn(),
  loadError: '',
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/api/captain/assistant', () => ({
  default: { playground: mocks.playground },
}));

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({ isFeatureFlagEnabled: mocks.isFeatureFlagEnabled }),
}));

vi.mock('./usePlaygroundSession', () => ({
  usePlaygroundSession: () => ({
    isInitializing: ref(false),
    loadError: ref(mocks.loadError),
    isValid: ref(true),
    playgroundConfig: computed(() => ({
      scenario_ids: [],
      temporary_scenarios: [],
      response_guidelines: [],
      guardrails: [],
      knowledge_text: '',
    })),
    configurationSummary: () => ({
      scenarioCount: 0,
      guidelineCount: 0,
      guardrailCount: 0,
      hasKnowledge: false,
    }),
    initialize: mocks.initialize,
    reset: mocks.reset,
  }),
}));

const ButtonStub = {
  props: ['disabled', 'icon'],
  emits: ['click'],
  template:
    '<button :data-icon="icon" :disabled="disabled" @click="$emit(\'click\')" />',
};

const MessageListStub = {
  props: ['messages', 'isLoading'],
  template: '<div data-test="messages" />',
};

let featureState;

const deferred = () => {
  let resolve;
  const promise = new Promise(resolvePromise => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
};

const mountPlayground = (assistantId = 7) =>
  shallowMount(AssistantPlayground, {
    props: { assistantId },
    global: {
      stubs: {
        NextButton: ButtonStub,
        MessageList: MessageListStub,
        PlaygroundTestSetup: true,
      },
    },
  });

describe('AssistantPlayground', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    featureState = reactive({ isV2: true });
    mocks.isFeatureFlagEnabled.mockImplementation(() => featureState.isV2);
    mocks.loadError = '';
    mocks.playground.mockResolvedValue({
      data: {
        response: 'Hello from Captain',
        agent_name: 'support_assistant',
        run_details: {
          handler: { title: 'Support assistant' },
          events: [],
          duration_ms: 20,
        },
      },
    });
  });

  it('sends a runtime snapshot and attaches run details to the response', async () => {
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(mocks.playground).toHaveBeenCalledWith({
      assistantId: 7,
      messageContent: 'Hello',
      messageHistory: [{ role: 'user', content: 'Hello' }],
      playgroundConfig: expect.objectContaining({ scenario_ids: [] }),
    });
    expect(
      wrapper.getComponent(MessageListStub).props('messages')[1]
    ).toMatchObject({
      content: 'Hello from Captain',
      runDetails: expect.objectContaining({ duration_ms: 20 }),
    });
  });

  it('shows request errors in the chat', async () => {
    mocks.playground.mockRejectedValue({
      response: { data: { error: 'Invalid playground configuration' } },
    });
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(
      wrapper.getComponent(MessageListStub).props('messages')[1]
    ).toMatchObject({
      content: 'Invalid playground configuration',
      isError: true,
    });
  });

  it('does not send an empty runtime snapshot when setup loading failed', async () => {
    mocks.loadError = 'The saved assistant setup could not be loaded.';
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });

    expect(mocks.playground).not.toHaveBeenCalled();
    expect(
      wrapper.getComponent(MessageListStub).props('messages')[0]
    ).toMatchObject({
      content: 'The saved assistant setup could not be loaded.',
      isError: true,
    });
  });

  it('constrains the setup panel wrapper on desktop', () => {
    const wrapper = mountPlayground();
    const setupWrapper = wrapper.getComponent({ name: 'PlaygroundTestSetup' })
      .element.parentElement;

    expect(setupWrapper.className).toContain('lg:w-[38rem]');
    expect(setupWrapper.className).toContain('lg:flex-none');
  });

  it('keeps the legacy playground UI and request contract unchanged', async () => {
    featureState.isV2 = false;
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(mocks.initialize).not.toHaveBeenCalled();
    expect(
      wrapper.findComponent({ name: 'PlaygroundTestSetup' }).exists()
    ).toBe(false);
    expect(wrapper.find('[data-icon="i-lucide-rotate-ccw"]').exists()).toBe(
      true
    );
    expect(wrapper.find('[data-icon="i-lucide-settings-2"]').exists()).toBe(
      false
    );
    expect(mocks.playground).toHaveBeenCalledWith(
      expect.objectContaining({ playgroundConfig: undefined })
    );
  });

  it('initializes saved setup when the V2 feature becomes available after mount', async () => {
    featureState.isV2 = false;
    mountPlayground();

    expect(mocks.initialize).not.toHaveBeenCalled();

    featureState.isV2 = true;
    await nextTick();

    expect(mocks.initialize).toHaveBeenCalledOnce();
  });

  it('clears messages and resets session state when assistants change', async () => {
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();
    expect(
      wrapper.getComponent(MessageListStub).props('messages')
    ).toHaveLength(2);

    await wrapper.setProps({ assistantId: 8 });
    await nextTick();

    expect(wrapper.getComponent(MessageListStub).props('messages')).toEqual([]);
    expect(mocks.reset).toHaveBeenCalled();
  });

  it('discards an in-flight response after the conversation is cleared', async () => {
    const playgroundRequest = deferred();
    mocks.playground.mockReturnValue(playgroundRequest.promise);
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });

    await wrapper.get('[data-icon="i-lucide-rotate-ccw"]').trigger('click');
    playgroundRequest.resolve({ data: { response: 'Stale response' } });
    await flushPromises();

    expect(wrapper.getComponent(MessageListStub).props('messages')).toEqual([]);
  });
});
