import { nextTick, ref } from 'vue';
import { shallowMount, flushPromises } from '@vue/test-utils';
import CopilotContainer from './CopilotContainer.vue';

const testState = vi.hoisted(() => ({
  dispatch: vi.fn(),
  refs: {},
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
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

const wrappers = [];
afterEach(() => {
  wrappers.forEach(wrapper => wrapper.unmount());
  wrappers.length = 0;
});
const mountComponent = () => {
  const wrapper = shallowMount(CopilotContainer, {
    global: {
      directives: { onClickOutside: {} },
      stubs: {
        Copilot: {
          name: 'Copilot',
          props: [
            'messages',
            'onSendMessage',
            'v2Enabled',
            'activeAssistant',
            'canSuggestReply',
            'selectedThread',
            'sessionKey',
            'history',
            'historyLoading',
            'historyError',
            'hasMoreHistory',
            'messagesLoading',
            'messagesError',
            'hasOlderMessages',
          ],
          template: '<div />',
        },
      },
    },
  });

  wrappers.push(wrapper);
  return wrapper;
};

describe('CopilotContainer', () => {
  beforeEach(() => {
    testState.dispatch.mockReset();
    testState.dispatch.mockResolvedValue(undefined);
    testState.refs.getSelectedChat.value = { id: 1 };
    testState.refs.getCurrentAccountId.value = 1;
    testState.refs['captainAssistants/getRecords'].value = [{ id: 7 }];
    testState.refs['accounts/isFeatureEnabledonAccount'].value = (_, flag) =>
      flag === 'captain_integration';
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

const thread = (id, assistant = null) => ({
  id,
  assistant,
  engine: 'v2',
  title: `Chat ${id}`,
  account_id: 1,
});
const page = (payload = [], nextPage = null) => ({
  payload,
  meta: { next_page: nextPage },
});
const enableV2 = () => {
  testState.refs['accounts/isFeatureEnabledonAccount'].value = (_, flag) =>
    flag === 'copilot_v2';
};
const setupV2 = () => {
  enableV2();
  testState.dispatch.mockImplementation(action => {
    if (action === 'copilotThreads/create') return Promise.resolve(thread(99));
    return Promise.resolve(page());
  });
  const wrapper = mountComponent();
  return { wrapper, copilot: wrapper.findComponent({ name: 'Copilot' }) };
};

describe('Copilot V2 sessions', () => {
  beforeEach(() => {
    testState.dispatch.mockReset();
    testState.refs.getCurrentAccountId.value = 1;
    testState.refs.getSelectedChat.value = { id: 1 };
    testState.refs['captainAssistants/getRecords'].value = [{ id: 7 }];
  });

  it('opens with only the V2 flag and sends without an assistant', async () => {
    testState.refs['captainAssistants/getRecords'].value = [];
    const { copilot } = setupV2();
    await flushPromises();
    expect(copilot.props('v2Enabled')).toBe(true);
    expect(copilot.props('activeAssistant')).toBeNull();
    expect(copilot.props('canSuggestReply')).toBe(false);
    expect(await copilot.props('onSendMessage')('Hello')).toBe(true);
    expect(testState.dispatch).toHaveBeenCalledWith('copilotThreads/create', {
      message: 'Hello',
      assistant_id: undefined,
      conversation_id: 1,
    });
  });

  it('defaults to no assistant, allows opting in and out, and protects reply suggestions', async () => {
    const { copilot } = setupV2();
    expect(copilot.props('activeAssistant')).toBeNull();
    expect(
      await copilot.props('onSendMessage')({
        message: 'Reply',
        requestType: 'reply_suggestion',
      })
    ).toBe(false);
    copilot.vm.$emit('setAssistant', { id: 7 });
    await nextTick();
    expect(copilot.props('activeAssistant')).toEqual({ id: 7 });
    expect(copilot.props('canSuggestReply')).toBe(true);
    copilot.vm.$emit('setAssistant', null);
    await nextTick();
    expect(copilot.props('activeAssistant')).toBeNull();
  });

  it('fetches pages, resumes using the saved assistant, and starts a fresh chat', async () => {
    const { copilot } = setupV2();
    await flushPromises();
    testState.dispatch.mockImplementation(action =>
      Promise.resolve(
        action === 'copilotMessages/getPage' ? page([], 2) : page()
      )
    );
    copilot.vm.$emit('selectThread', thread(10, { id: 42 }));
    await flushPromises();
    expect(copilot.props('messages')).toEqual([{ id: 10 }]);
    expect(copilot.props('activeAssistant')).toEqual({ id: 42 });
    expect(copilot.props('hasOlderMessages')).toBe(true);
    copilot.vm.$emit('loadMessages');
    await flushPromises();
    expect(testState.dispatch).toHaveBeenCalledWith('copilotMessages/getPage', {
      threadId: 10,
      page: 2,
    });
    await copilot.props('onSendMessage')('Continue');
    expect(testState.dispatch).toHaveBeenCalledWith('copilotMessages/create', {
      assistant_id: 42,
      conversation_id: null,
      threadId: 10,
      message: 'Continue',
    });
    copilot.vm.$emit('setAssistant', { id: 7 });
    await nextTick();
    expect(copilot.props('activeAssistant')).toEqual({ id: 42 });
    copilot.vm.$emit('reset');
    await nextTick();
    expect(copilot.props('messages')).toEqual([]);
    expect(copilot.props('activeAssistant')).toBeNull();
    expect(copilot.props('selectedThread')).toBeNull();
  });

  it('appends history pages without duplicating sessions', async () => {
    enableV2();
    testState.dispatch.mockResolvedValue(page([thread(10)], 2));
    const wrapper = mountComponent();
    const copilot = wrapper.findComponent({ name: 'Copilot' });
    await flushPromises();
    expect(copilot.props('hasMoreHistory')).toBe(true);
    testState.dispatch.mockResolvedValue(page([thread(10), thread(9)]));
    copilot.vm.$emit('loadHistory');
    await flushPromises();
    expect(testState.dispatch).toHaveBeenCalledWith('copilotThreads/getPage', {
      page: 2,
    });
    expect(copilot.props('history').map(item => item.id)).toEqual([10, 9]);
    expect(copilot.props('hasMoreHistory')).toBe(false);
  });

  it('refreshes history after creation without letting an older list hide the new chat', async () => {
    enableV2();
    let finishOldList;
    let listCalls = 0;
    testState.dispatch.mockImplementation(action => {
      if (action === 'copilotThreads/create')
        return Promise.resolve(thread(99));
      if (action === 'copilotThreads/getPage') {
        listCalls += 1;
        if (listCalls === 1)
          return new Promise(resolve => {
            finishOldList = resolve;
          });
        return Promise.resolve(page([thread(99)]));
      }
      return Promise.resolve(page());
    });
    const wrapper = mountComponent();
    const copilot = wrapper.findComponent({ name: 'Copilot' });
    await copilot.props('onSendMessage')('New request');
    await flushPromises();
    finishOldList(page());
    await flushPromises();
    expect(copilot.props('history').map(item => item.id)).toEqual([99]);
  });

  it('ignores create completion after New chat', async () => {
    const { copilot } = setupV2();
    await flushPromises();
    let finish;
    testState.dispatch.mockImplementation(
      () =>
        new Promise(resolve => {
          finish = resolve;
        })
    );
    const send = copilot.props('onSendMessage')('Hello');
    copilot.vm.$emit('reset');
    await nextTick();
    finish(thread(99));
    await send;
    expect(copilot.props('selectedThread')).toBeNull();
  });

  it('ignores stale message loading state after selecting another session', async () => {
    const { copilot } = setupV2();
    await flushPromises();
    let finish;
    testState.dispatch.mockImplementation((action, params) => {
      if (params.threadId === 10)
        return new Promise(resolve => {
          finish = resolve;
        });
      return Promise.resolve(page());
    });
    copilot.vm.$emit('selectThread', thread(10));
    copilot.vm.$emit('selectThread', thread(11));
    await flushPromises();
    finish(page([], 2));
    await flushPromises();
    expect(copilot.props('selectedThread').id).toBe(11);
    expect(copilot.props('hasOlderMessages')).toBe(false);
    expect(copilot.props('messagesLoading')).toBe(false);
  });

  it('clears sessions on account switch and ignores old history results', async () => {
    const { copilot } = setupV2();
    await flushPromises();
    let finish;
    testState.dispatch.mockImplementation(action => {
      if (action === 'copilotThreads/getPage')
        return new Promise(resolve => {
          finish = resolve;
        });
      return Promise.resolve(page());
    });
    copilot.vm.$emit('loadHistory');
    const oldFinish = finish;
    testState.refs.getCurrentAccountId.value = 2;
    await nextTick();
    finish(page([thread(20)]));
    await flushPromises();
    oldFinish(page([thread(10)]));
    await flushPromises();
    expect(copilot.props('history').map(item => item.id)).toEqual([20]);
    expect(copilot.props('selectedThread')).toBeNull();
  });

  it('shows a retryable message failure and prevents sending into incomplete history', async () => {
    const { copilot } = setupV2();
    await flushPromises();
    testState.dispatch.mockRejectedValue(new Error('Offline'));
    copilot.vm.$emit('selectThread', thread(10));
    await flushPromises();
    expect(copilot.props('messagesError')).toBe(true);
    expect(await copilot.props('onSendMessage')('Continue')).toBe(false);
    testState.dispatch.mockResolvedValue(page());
    copilot.vm.$emit('loadMessages');
    await flushPromises();
    expect(copilot.props('messagesError')).toBe(false);
    expect(testState.dispatch).toHaveBeenLastCalledWith(
      'copilotMessages/getPage',
      { threadId: 10, page: 1 }
    );
  });

  it('retries a failed older page without skipping it or discarding visible messages', async () => {
    const { copilot } = setupV2();
    await flushPromises();
    testState.dispatch.mockResolvedValue(page([], 2));
    copilot.vm.$emit('selectThread', thread(10));
    await flushPromises();
    testState.dispatch.mockRejectedValue(new Error('Offline'));
    copilot.vm.$emit('loadMessages');
    await flushPromises();
    expect(copilot.props('messagesError')).toBe(true);
    expect(copilot.props('messages')).toEqual([{ id: 10 }]);
    testState.dispatch.mockResolvedValue(page());
    copilot.vm.$emit('loadMessages');
    await flushPromises();
    expect(testState.dispatch).toHaveBeenLastCalledWith(
      'copilotMessages/getPage',
      { threadId: 10, page: 2 }
    );
    expect(copilot.props('messagesError')).toBe(false);
    expect(copilot.props('hasOlderMessages')).toBe(false);
  });
});
