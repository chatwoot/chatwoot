import { computed, nextTick, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import AssistantPlayground from './AssistantPlayground.vue';

const mocks = vi.hoisted(() => ({
  playground: vi.fn(),
  initialize: vi.fn(),
  reset: vi.fn(),
  loadError: '',
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/api/captain/assistant', () => ({
  default: { playground: mocks.playground },
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

  it('clears messages and resets session state when assistants change', async () => {
    const wrapper = mountPlayground();
    const keyBefore = wrapper.getComponent({ name: 'PlaygroundTestSetup' }).vm.$
      .vnode.key;
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
    expect(
      wrapper.getComponent({ name: 'PlaygroundTestSetup' }).vm.$.vnode.key
    ).toBe(keyBefore + 1);
  });

  it.each([
    ['conversation is cleared', 'i-lucide-rotate-ccw'],
    ['test setup is reset', 'i-lucide-refresh-cw'],
  ])(
    'keeps new requests locked while discarding an in-flight response after the %s',
    async (_action, icon) => {
      const playgroundRequest = deferred();
      mocks.playground.mockReturnValue(playgroundRequest.promise);
      const wrapper = mountPlayground();
      await wrapper.get('input').setValue('Hello');
      await wrapper.get('input').trigger('keydown', { key: 'Enter' });

      await wrapper.get(`[data-icon="${icon}"]`).trigger('click');
      await wrapper.get('input').setValue('Try again');
      await wrapper.get('input').trigger('keydown', { key: 'Enter' });

      expect(mocks.playground).toHaveBeenCalledOnce();
      expect(
        wrapper.get('[data-icon="i-lucide-send"]').attributes()
      ).toHaveProperty('disabled');

      playgroundRequest.resolve({ data: { response: 'Stale response' } });
      await flushPromises();

      expect(wrapper.getComponent(MessageListStub).props('messages')).toEqual(
        []
      );
      expect(
        wrapper.get('[data-icon="i-lucide-send"]').attributes()
      ).not.toHaveProperty('disabled');

      await wrapper.get('input').trigger('keydown', { key: 'Enter' });
      expect(mocks.playground).toHaveBeenCalledTimes(2);
    }
  );
});
