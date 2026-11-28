import { nextTick, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CopilotContainer from './CopilotContainer.vue';

const testState = vi.hoisted(() => ({
  dispatch: vi.fn(),
  track: vi.fn(),
  getThreads: vi.fn(),
  refs: {},
  route: {},
  router: { push: vi.fn(), replace: vi.fn(), back: vi.fn() },
  uiSettings: null,
  updateUISettings: vi.fn(),
}));

vi.mock('vue-router', async () => {
  const { reactive } = await import('vue');
  const route = reactive({ name: 'home', params: {} });
  testState.route = route;

  return { useRoute: () => route, useRouter: () => testState.router };
});
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
  useTrack: testState.track,
}));
vi.mock('dashboard/api/captain/copilotThreads', () => ({
  default: { get: testState.getThreads },
}));
vi.mock('dashboard/composables/useConfig', () => ({
  useConfig: () => ({ isEnterprise: true }),
}));
vi.mock('dashboard/composables/useUISettings', async () => {
  const { ref: createRef } = await import('vue');
  testState.uiSettings = createRef({});
  return {
    useUISettings: () => ({
      uiSettings: testState.uiSettings,
      updateUISettings: testState.updateUISettings,
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
    'accounts/getAccount': createRef(() => ({ settings: {} })),
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
            'isExpanded',
            'canUseReply',
            'draft',
          ],
          emits: [
            'reset',
            'setAssistant',
            'selectThread',
            'loadMoreThreads',
            'toggleExpand',
            'close',
            'update:draft',
          ],
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
    testState.uiSettings.value = { is_copilot_panel_open: true };
    testState.updateUISettings.mockReset();
    testState.route.name = 'home';
    testState.route.params = {};
    Object.values(testState.router).forEach(navigate => navigate.mockReset());
    window.history.replaceState(null, '');
    testState.refs.getSelectedChat.value = { id: 1 };
    testState.refs.getCurrentAccountId.value = 1;
    testState.refs['accounts/getAccount'].value = () => ({ settings: {} });
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

  it('uses up the dot when the panel is already open', async () => {
    mountComponent();
    await flushPromises();

    expect(testState.updateUISettings).toHaveBeenCalledWith({
      copilot_dot_dismissed: true,
    });
  });

  it('opens its own page from the expand button when no conversation is open', async () => {
    testState.refs.getSelectedChat.value = {};
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });
    expect(copilot.props('isExpanded')).toBe(false);

    copilot.vm.$emit('toggleExpand');

    expect(testState.router.push).toHaveBeenCalledWith({
      name: 'copilot_index',
      params: { threadId: '' },
    });
  });

  it('expands in place without a conversation for an account on the classic layout', async () => {
    testState.refs.getSelectedChat.value = {};
    testState.refs['accounts/getAccount'].value = () => ({
      settings: { copilot_classic_layout: true },
    });
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    copilot.vm.$emit('toggleExpand');
    await nextTick();

    expect(testState.router.push).not.toHaveBeenCalled();
    expect(copilot.props('isExpanded')).toBe(true);
  });

  it('takes the open chat along when it expands', async () => {
    testState.refs.getSelectedChat.value = {};
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });
    copilot.vm.$emit('selectThread', { id: 42 });
    await flushPromises();

    copilot.vm.$emit('toggleExpand');

    expect(testState.router.push).toHaveBeenCalledWith({
      name: 'copilot_index',
      params: { threadId: 42 },
    });
  });

  it('expands in place inside a conversation and keeps asking about it', async () => {
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    copilot.vm.$emit('toggleExpand');
    await nextTick();

    expect(testState.router.push).not.toHaveBeenCalled();
    expect(copilot.props('isExpanded')).toBe(true);

    await copilot.props('onSendMessage')('Draft a reply');

    expect(testState.dispatch).toHaveBeenCalledWith(
      'copilotThreads/create',
      expect.objectContaining({ conversation_id: 1 })
    );

    copilot.vm.$emit('toggleExpand');
    await nextTick();

    expect(copilot.props('isExpanded')).toBe(false);
    expect(testState.router.push).not.toHaveBeenCalled();
  });

  it('puts the open chat in the address when its page opens', async () => {
    const wrapper = mountComponent();
    await flushPromises();
    wrapper
      .findComponent({ name: 'Copilot' })
      .vm.$emit('selectThread', { id: 42 });
    await flushPromises();

    testState.route.name = 'copilot_index';
    await nextTick();

    expect(testState.router.replace).toHaveBeenCalledWith({
      name: 'copilot_index',
      params: { threadId: 42 },
    });
  });

  it('opens the chat named in the address of its page', async () => {
    testState.route.name = 'copilot_index';
    testState.route.params = { threadId: '42' };

    const wrapper = mountComponent();
    await flushPromises();

    expect(testState.dispatch).toHaveBeenCalledWith(
      'copilotMessages/fetchThread',
      { threadId: 42 }
    );
    expect(
      wrapper.findComponent({ name: 'Copilot' }).props('selectedThreadId')
    ).toBe(42);
  });

  it('does not offer a suggested reply for use when no conversation is open', async () => {
    testState.refs.getSelectedChat.value = {};
    testState.route.name = 'copilot_index';
    testState.route.params = { threadId: '42' };

    const wrapper = mountComponent();
    await flushPromises();

    expect(
      wrapper.findComponent({ name: 'Copilot' }).props('canUseReply')
    ).toBe(false);
  });

  it('puts a new chat in the address of its page', async () => {
    testState.route.name = 'copilot_index';
    testState.dispatch.mockImplementation(action =>
      action === 'copilotThreads/create'
        ? Promise.resolve({ id: 99 })
        : Promise.resolve()
    );
    const wrapper = mountComponent();
    await flushPromises();

    await wrapper.findComponent({ name: 'Copilot' }).props('onSendMessage')(
      'New question'
    );

    expect(testState.router.replace).toHaveBeenCalledWith({
      name: 'copilot_index',
      params: { threadId: 99 },
    });
  });

  it('shows Copilot full screen on its page, even with the panel closed', async () => {
    testState.uiSettings.value = { is_copilot_panel_open: false };
    testState.route.name = 'copilot_index';

    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.findComponent({ name: 'Copilot' }).props('isExpanded')).toBe(
      true
    );
  });

  it('returns beside the page the person came from when it shrinks', async () => {
    testState.route.name = 'copilot_index';
    window.history.replaceState({ back: '/app/accounts/1/dashboard' }, '');
    const wrapper = mountComponent();
    await flushPromises();

    wrapper.findComponent({ name: 'Copilot' }).vm.$emit('toggleExpand');

    expect(testState.updateUISettings).toHaveBeenCalledWith({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: true,
    });
    expect(testState.router.back).toHaveBeenCalled();
  });

  it('goes to the conversations when its page is closed with no page to return to', async () => {
    testState.route.name = 'copilot_index';
    const wrapper = mountComponent();
    await flushPromises();

    wrapper.findComponent({ name: 'Copilot' }).vm.$emit('close');

    expect(testState.router.replace).toHaveBeenCalledWith({ name: 'home' });
  });

  it('stays on the page it is beside when the panel is closed', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    wrapper.findComponent({ name: 'Copilot' }).vm.$emit('close');

    expect(testState.router.back).not.toHaveBeenCalled();
    expect(testState.router.replace).not.toHaveBeenCalled();
  });

  it('starts a new chat on its own page for a question asked outside the panel', async () => {
    const thread = { id: 42, title: 'Older question', assistant: { id: 7 } };
    testState.getThreads.mockResolvedValue({
      data: { payload: [thread], meta: { total_count: 1, page: 1 } },
    });
    testState.dispatch.mockImplementation(action =>
      action === 'copilotThreads/create'
        ? Promise.resolve({ id: 99, title: 'Picked prompt' })
        : Promise.resolve()
    );
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });
    copilot.vm.$emit('selectThread', thread);
    await flushPromises();

    emitter.emit(BUS_EVENTS.ASK_COPILOT, 'Picked prompt');
    await flushPromises();

    expect(testState.dispatch).toHaveBeenCalledWith('copilotThreads/create', {
      assistant_id: 7,
      conversation_id: 1,
      message: 'Picked prompt',
    });
    expect(copilot.props('selectedThreadId')).toBe(99);
    expect(testState.router.push).toHaveBeenCalledWith({
      name: 'copilot_index',
    });
    expect(testState.track).toHaveBeenCalledWith('Copilot: Sent a message');
    wrapper.unmount();
  });

  it('keeps a question asked outside the panel when it could not be sent', async () => {
    testState.dispatch.mockRejectedValue(new Error('Could not send'));
    const wrapper = mountComponent();
    await flushPromises();

    emitter.emit(BUS_EVENTS.ASK_COPILOT, 'Typed question');
    await flushPromises();

    expect(wrapper.findComponent({ name: 'Copilot' }).props('draft')).toBe(
      'Typed question'
    );
    wrapper.unmount();
  });

  it('keeps text typed while a question asked outside the panel failed to send', async () => {
    let rejectSend;
    testState.dispatch.mockImplementation(action =>
      action === 'copilotThreads/create'
        ? new Promise((resolve, reject) => {
            rejectSend = reject;
          })
        : Promise.resolve()
    );
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });

    emitter.emit(BUS_EVENTS.ASK_COPILOT, 'First question');
    await nextTick();
    copilot.vm.$emit('update:draft', 'Second question');
    await nextTick();
    rejectSend(new Error('Could not send'));
    await flushPromises();

    expect(copilot.props('draft')).toBe('Second question');
    wrapper.unmount();
  });

  it('drops older unsent text when a question is asked outside the panel', async () => {
    testState.dispatch.mockImplementation(action =>
      action === 'copilotThreads/create'
        ? Promise.resolve({ id: 99 })
        : Promise.resolve()
    );
    const wrapper = mountComponent();
    await flushPromises();
    const copilot = wrapper.findComponent({ name: 'Copilot' });
    copilot.vm.$emit('update:draft', 'Older unsent text');
    await nextTick();

    emitter.emit(BUS_EVENTS.ASK_COPILOT, 'New question');
    await flushPromises();

    expect(copilot.props('draft')).toBe('');
    wrapper.unmount();
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

  it('keeps the open thread when another conversation opens, and its reply only fits the first one', async () => {
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
    expect(copilot.props('canUseReply')).toBe(true);

    testState.refs.getSelectedChat.value = { id: 2 };
    await nextTick();

    expect(copilot.props('messages')).toEqual([{ id: 99 }]);
    expect(copilot.props('canUseReply')).toBe(false);
  });

  it('opens a thread created while another conversation was opened', async () => {
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
    expect(copilot.props('selectedThreadId')).toBe(99);
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
