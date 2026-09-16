import { computed, nextTick, reactive, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import AssistantPlayground from './AssistantPlayground.vue';

const mocks = vi.hoisted(() => ({
  playground: vi.fn(),
  initialize: vi.fn(),
  reset: vi.fn(),
  isFeatureFlagEnabled: vi.fn(),
  loadError: '',
  eventHandlers: {},
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

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    on: vi.fn((event, handler) => {
      mocks.eventHandlers[event] = handler;
    }),
    off: vi.fn(event => {
      delete mocks.eventHandlers[event];
    }),
  },
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

const emitPlaygroundResponse = payload => {
  mocks.eventHandlers.CAPTAIN_PLAYGROUND_RESPONSE(payload);
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
    mocks.eventHandlers = {};
    mocks.playground.mockResolvedValue({ data: { request_id: 'accepted' } });
  });

  it('sends a runtime snapshot and displays the WebSocket response', async () => {
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();

    expect(mocks.playground).toHaveBeenCalledWith(
      expect.objectContaining({
        assistantId: 7,
        messageContent: 'Hello',
        messageHistory: [{ role: 'user', content: 'Hello' }],
        playgroundConfig: expect.objectContaining({ scenario_ids: [] }),
        requestId: expect.stringMatching(/^playground-/),
      })
    );
    expect(
      wrapper.getComponent(MessageListStub).props('messages')
    ).toHaveLength(1);
    expect(wrapper.getComponent(MessageListStub).props('isLoading')).toBe(true);

    const { requestId } = mocks.playground.mock.calls[0][0];
    emitPlaygroundResponse({
      request_id: requestId,
      response: 'Hello from Captain',
      agent_name: 'support_assistant',
      run_details: {
        handler: { title: 'Support assistant' },
        events: [],
        duration_ms: 20,
      },
    });
    await nextTick();

    expect(
      wrapper.getComponent(MessageListStub).props('messages')[1]
    ).toMatchObject({
      content: 'Hello from Captain',
      runDetails: expect.objectContaining({ duration_ms: 20 }),
    });
    expect(wrapper.getComponent(MessageListStub).props('isLoading')).toBe(
      false
    );
  });

  it('shows worker errors delivered through the WebSocket', async () => {
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();

    const { requestId } = mocks.playground.mock.calls[0][0];
    emitPlaygroundResponse({
      request_id: requestId,
      error: 'Invalid playground configuration',
    });
    await nextTick();

    expect(
      wrapper.getComponent(MessageListStub).props('messages')[1]
    ).toMatchObject({
      content: 'Invalid playground configuration',
      isError: true,
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

    expect(setupWrapper.tagName).toBe('ASIDE');
    expect(setupWrapper.className).toMatch(/w-\[\d+rem\]/);
    expect(setupWrapper.className).toContain('flex-none');
  });

  it('resets the test setup and remounts the panel to clear its drafts', async () => {
    const wrapper = mountPlayground();
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();
    const keyBefore = wrapper.getComponent({ name: 'PlaygroundTestSetup' }).vm.$
      .vnode.key;

    await wrapper.get('[data-icon="i-lucide-refresh-cw"]').trigger('click');
    await flushPromises();

    expect(mocks.reset).toHaveBeenCalledOnce();
    expect(wrapper.getComponent(MessageListStub).props('messages')).toEqual([]);
    expect(
      wrapper.getComponent({ name: 'PlaygroundTestSetup' }).vm.$.vnode.key
    ).toBe(keyBefore + 1);
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
    const keyBefore = wrapper.getComponent({ name: 'PlaygroundTestSetup' }).vm.$
      .vnode.key;
    await wrapper.get('input').setValue('Hello');
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    await flushPromises();
    emitPlaygroundResponse({
      request_id: mocks.playground.mock.calls[0][0].requestId,
      response: 'Hello from Captain',
    });
    await nextTick();
    expect(
      wrapper.getComponent(MessageListStub).props('messages')
    ).toHaveLength(2);

    await wrapper.setProps({ assistantId: 8 });
    await nextTick();

    expect(wrapper.getComponent(MessageListStub).props('messages')).toEqual([]);
    expect(mocks.reset).toHaveBeenCalled();
    expect(
      wrapper.getComponent({ name: 'PlaygroundTestSetup' }).vm.$.vnode.key
    ).toBe(keyBefore + 1);
  });

  it.each([
    ['conversation is cleared', 'i-lucide-rotate-ccw'],
    ['test setup is reset', 'i-lucide-refresh-cw'],
  ])(
    'discards an old WebSocket response after the %s',
    async (_action, icon) => {
      const wrapper = mountPlayground();
      await wrapper.get('input').setValue('Hello');
      await wrapper.get('input').trigger('keydown', { key: 'Enter' });
      await flushPromises();
      const firstRequestId = mocks.playground.mock.calls[0][0].requestId;

      await wrapper.get(`[data-icon="${icon}"]`).trigger('click');
      await flushPromises();
      await wrapper.get('input').setValue('Try again');
      await wrapper.get('input').trigger('keydown', { key: 'Enter' });
      await flushPromises();
      const secondRequestId = mocks.playground.mock.calls[1][0].requestId;

      expect(mocks.playground).toHaveBeenCalledTimes(2);

      emitPlaygroundResponse({
        request_id: firstRequestId,
        response: 'Stale response',
      });
      await nextTick();

      expect(wrapper.getComponent(MessageListStub).props('messages')).toEqual([
        expect.objectContaining({ content: 'Try again', sender: 'user' }),
      ]);

      emitPlaygroundResponse({
        request_id: secondRequestId,
        response: 'Fresh response',
      });
      await nextTick();

      expect(
        wrapper.getComponent(MessageListStub).props('messages')[1]
      ).toMatchObject({ content: 'Fresh response', sender: 'assistant' });
    }
  );
});
