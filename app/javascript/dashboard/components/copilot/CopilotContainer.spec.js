import { nextTick, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import CopilotContainer from './CopilotContainer.vue';

const testState = vi.hoisted(() => ({
  dispatch: vi.fn(),
  getThreads: vi.fn(),
  refs: {},
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/api/captain/copilotThreads', () => ({
  default: { get: testState.getThreads },
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
    'accounts/isFeatureEnabledonAccount': createRef(
      (accountId, flag) => flag === 'captain_integration'
    ),
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
          props: [
            'messages',
            'onSendMessage',
            'threads',
            'selectedThreadId',
            'hasMoreThreads',
            'isLoadingThreads',
            'isLoadingSelectedThread',
          ],
          emits: ['reset', 'setAssistant', 'selectThread', 'loadMoreThreads'],
          template: '<div />',
        },
      },
    },
  });

describe('CopilotContainer', () => {
  beforeEach(() => {
    testState.dispatch.mockReset();
    testState.dispatch.mockResolvedValue(undefined);
    testState.getThreads.mockReset();
    testState.getThreads.mockResolvedValue({
      data: { payload: [], meta: { total_count: 0, page: 1 } },
    });
    testState.refs.getSelectedChat.value = { id: 1 };
    testState.refs.getCurrentAccountId.value = 1;
    testState.refs['accounts/isFeatureEnabledonAccount'].value = (
      accountId,
      flag
    ) => flag === 'captain_integration';
  });

  it('does not load history when Copilot is unavailable', async () => {
    testState.refs['accounts/isFeatureEnabledonAccount'].value = () => false;

    mountComponent();
    await flushPromises();

    expect(testState.getThreads).not.toHaveBeenCalled();
  });

  it('lists and opens a past chat', async () => {
    const thread = { id: 42, title: 'Older question', assistant: { id: 7 } };
    testState.getThreads.mockResolvedValue({
      data: { payload: [thread], meta: { total_count: 1, page: 1 } },
    });
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    expect(copilot.props('threads')).toEqual([thread]);

    copilot.vm.$emit('selectThread', thread);
    await flushPromises();

    expect(testState.dispatch).toHaveBeenCalledWith(
      'copilotMessages/fetchThread',
      { threadId: 42 }
    );
    expect(copilot.props('selectedThreadId')).toBe(42);
  });

  it('keeps a newly created chat when the initial history request finishes later', async () => {
    let resolveHistory;
    testState.getThreads.mockImplementation(
      () =>
        new Promise(resolve => {
          resolveHistory = resolve;
        })
    );
    testState.dispatch.mockImplementation(action =>
      action === 'copilotThreads/create'
        ? Promise.resolve({ id: 99, title: 'New question' })
        : Promise.resolve()
    );
    const wrapper = mountComponent();
    await nextTick();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    await copilot.props('onSendMessage')('New question');
    expect(copilot.props('threads')).toEqual([
      { id: 99, title: 'New question' },
    ]);

    resolveHistory({
      data: {
        payload: [{ id: 42, title: 'Older question' }],
        meta: { total_count: 1, page: 1 },
      },
    });
    await flushPromises();

    expect(copilot.props('threads')).toEqual([
      { id: 99, title: 'New question' },
      { id: 42, title: 'Older question' },
    ]);
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

  it('ignores a thread created for an account that is no longer selected', async () => {
    let resolveRequest;
    testState.dispatch.mockImplementation(action => {
      if (action !== 'copilotThreads/create') return Promise.resolve();
      return new Promise(resolve => {
        resolveRequest = resolve;
      });
    });
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    const sendPromise = copilot.props('onSendMessage')('Draft a reply');
    await nextTick();
    testState.refs.getCurrentAccountId.value = 2;
    await nextTick();
    resolveRequest({ id: 99, title: 'Previous account thread' });

    expect(await sendPromise).toBe(true);
    expect(copilot.props('selectedThreadId')).toBeNull();
    expect(copilot.props('threads')).toEqual([]);
  });

  it('reports a failed send', async () => {
    testState.dispatch.mockRejectedValue(new Error('Could not send'));
    const wrapper = mountComponent();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    const result = await copilot.props('onSendMessage')('Draft a reply');

    expect(result).toBe(false);
  });
});
