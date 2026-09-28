import { nextTick, ref } from 'vue';
import { shallowMount } from '@vue/test-utils';
import CopilotContainer from './CopilotContainer.vue';

const testState = vi.hoisted(() => ({
  dispatch: vi.fn(),
  refs: {},
  copilotAssistantId: null,
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/store/captain/preferences', () => ({
  useCaptainConfigStore: () => ({
    copilotAssistantId: testState.copilotAssistantId,
    fetch: vi.fn(),
  }),
}));
vi.mock('dashboard/api/captain/copilotThreads', () => ({
  default: {
    get: vi
      .fn()
      .mockResolvedValue({ data: { payload: [], meta: { total_count: 0 } } }),
  },
}));
vi.mock('dashboard/composables/useConfig', () => ({
  useConfig: () => ({ isEnterprise: true }),
}));
vi.mock('dashboard/composables/useUISettings', async () => {
  const { ref: createRef } = await import('vue');
  return {
    useUISettings: () => ({
      uiSettings: createRef({ is_copilot_panel_open: true }),
      updateUISettings: vi.fn(),
    }),
  };
});
vi.mock('@vueuse/core', () => ({
  useWindowSize: () => ({ width: ref(1024) }),
}));
vi.mock('dashboard/composables/store', async () => {
  const { ref: createRef } = await import('vue');
  const refs = {
    getCurrentUser: createRef({ id: 1 }),
    'captainAssistants/getRecords': createRef([{ id: 7 }]),
    'captainAssistants/getUIFlags': createRef({ fetchingList: false }),
    getCopilotAssistant: createRef(null),
    getSelectedChat: createRef({ id: 1 }),
    getLastEmailInSelectedChat: createRef({ message_type: 0 }),
    getCurrentAccountId: createRef(1),
    'accounts/isFeatureEnabledonAccount': createRef(() => true),
  };
  testState.refs = refs;

  return {
    useMapGetter: key => refs[key],
    useStore: () => ({
      dispatch: testState.dispatch,
      getters: {
        'copilotMessages/getMessagesByThreadId': threadId =>
          threadId ? [{ id: threadId }] : [],
      },
    }),
  };
});

const mountComponent = () =>
  shallowMount(CopilotContainer, {
    global: {
      directives: { onClickOutside: {} },
      stubs: {
        Copilot: {
          name: 'Copilot',
          props: ['messages', 'onSendMessage', 'selectedThreadId'],
          template: '<div />',
        },
      },
    },
  });

describe('CopilotContainer', () => {
  beforeEach(() => {
    testState.dispatch.mockReset();
    testState.dispatch.mockResolvedValue(undefined);
    testState.refs.getSelectedChat.value = { id: 1 };
    testState.refs['captainAssistants/getRecords'].value = [{ id: 7 }];
    testState.copilotAssistantId = null;
  });

  it('keeps the existing assistant when no account choice is saved', async () => {
    testState.dispatch.mockImplementation(action =>
      Promise.resolve(
        action === 'copilotThreads/create' ? { id: 99 } : undefined
      )
    );
    const wrapper = mountComponent();

    await wrapper.findComponent({ name: 'Copilot' }).props('onSendMessage')(
      'Hello'
    );

    expect(testState.dispatch).toHaveBeenCalledWith(
      'copilotThreads/create',
      expect.objectContaining({ assistant_id: 7 })
    );
  });

  it('uses the saved account assistant for a new chat', async () => {
    testState.copilotAssistantId = 8;
    testState.refs['captainAssistants/getRecords'].value = [
      { id: 7 },
      { id: 8 },
    ];
    testState.dispatch.mockImplementation(action =>
      Promise.resolve(
        action === 'copilotThreads/create' ? { id: 99 } : undefined
      )
    );
    const wrapper = mountComponent();

    await wrapper.findComponent({ name: 'Copilot' }).props('onSendMessage')(
      'Hello'
    );

    expect(testState.dispatch).toHaveBeenCalledWith(
      'copilotThreads/create',
      expect.objectContaining({ assistant_id: 8 })
    );
  });

  it('opens a past chat and starts a fresh chat without deleting it', async () => {
    const wrapper = mountComponent();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    copilot.vm.$emit('selectThread', { id: 42 });
    await nextTick();
    await nextTick();

    expect(testState.dispatch).toHaveBeenCalledWith('copilotMessages/get', 42);
    expect(copilot.props('selectedThreadId')).toBe(42);

    copilot.vm.$emit('reset');
    await nextTick();

    expect(copilot.props('selectedThreadId')).toBeNull();
  });

  it('clears the selected thread when the conversation changes', async () => {
    testState.dispatch.mockImplementation(action =>
      action === 'copilotThreads/create'
        ? Promise.resolve({ id: 99 })
        : Promise.resolve()
    );
    const wrapper = mountComponent();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    const result = await copilot.props('onSendMessage')('Draft a reply');

    expect(result).toBe(true);
    expect(copilot.props('messages')).toEqual([{ id: 99 }]);

    testState.refs.getSelectedChat.value = { id: 2 };
    await nextTick();

    expect(copilot.props('messages')).toEqual([]);
  });

  it('ignores a thread created for a conversation that is no longer selected', async () => {
    let resolveRequest;
    testState.dispatch.mockImplementation(action => {
      if (action !== 'copilotThreads/create') return Promise.resolve();
      return new Promise(resolve => {
        resolveRequest = resolve;
      });
    });
    const wrapper = mountComponent();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    const sendPromise = copilot.props('onSendMessage')('Draft a reply');
    await nextTick();
    testState.refs.getSelectedChat.value = { id: 2 };
    await nextTick();
    resolveRequest({ id: 99 });

    expect(await sendPromise).toBe(true);

    expect(copilot.props('messages')).toEqual([]);
  });

  it('reports a failed send', async () => {
    testState.dispatch.mockRejectedValue(new Error('Could not send'));
    const wrapper = mountComponent();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    const result = await copilot.props('onSendMessage')('Draft a reply');

    expect(result).toBe(false);
  });
});
