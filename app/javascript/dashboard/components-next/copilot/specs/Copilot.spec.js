import { mount, shallowMount } from '@vue/test-utils';

import Copilot from '../Copilot.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import ToggleCopilotAssistant from '../ToggleCopilotAssistant.vue';
import CopilotInput from '../CopilotInput.vue';
import CopilotThinkingGroup from '../CopilotThinkingGroup.vue';
import CopilotReviewProgress from '../CopilotReviewProgress.vue';
import CopilotLoader from '../CopilotLoader.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useTrack: vi.fn(),
}));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ updateUISettings: vi.fn() }),
}));

const mountComponent = (props = {}) =>
  shallowMount(Copilot, {
    props: { onSendMessage: vi.fn(), ...props },
    global: { mocks: { $t: key => key } },
  });

describe('Copilot', () => {
  it('gives every header action an accessible name', () => {
    const wrapper = mount(SidebarActionsHeader, {
      props: {
        title: 'Copilot',
        buttons: [
          {
            key: 'history',
            icon: 'i-lucide-history',
            tooltip: 'History',
          },
          {
            key: 'new',
            icon: 'i-lucide-square-pen',
            tooltip: 'New chat',
          },
        ],
      },
      global: {
        mocks: { $t: key => key },
      },
    });

    expect(
      wrapper.findAll('button').map(button => button.attributes('aria-label'))
    ).toEqual(['History', 'New chat', 'GENERAL.CLOSE']);
  });

  it('opens a past chat and starts a new one', async () => {
    const thread = { id: 42, title: 'Older question' };
    const wrapper = mountComponent({ threads: [thread] });
    const header = wrapper.findComponent(SidebarActionsHeader);

    await header.vm.$emit('click', 'history');
    const olderChat = wrapper
      .findAll('button')
      .find(button => button.text().includes(thread.title));
    await olderChat.trigger('click');

    expect(wrapper.emitted('selectThread')).toEqual([[thread]]);

    await header.vm.$emit('click', 'new');
    expect(wrapper.emitted('reset')).toHaveLength(1);
  });

  it('hides the assistant selector for a saved chat', () => {
    const assistants = [
      { id: 7, name: 'Support' },
      { id: 8, name: 'Sales' },
    ];

    const wrapper = mountComponent({
      assistants,
      activeAssistant: assistants[0],
      selectedThreadId: 42,
    });

    expect(wrapper.findComponent(ToggleCopilotAssistant).exists()).toBe(false);
  });

  const step = (id, content) => ({
    id,
    message_type: 'assistant_thinking',
    message: { content, run_id: 9 },
  });

  it('splits the steps around a review and shows only the newest step live', () => {
    const progress = { finished: false, done: 5, total: 300, matched: 1 };
    const wrapper = mountComponent({
      messages: [
        step(1, 'Finding matching records'),
        { id: 2, message_type: 'assistant_progress', message: { progress } },
        step(3, 'Preparing the results'),
      ],
    });

    const groups = wrapper.findAllComponents(CopilotThinkingGroup);
    expect(groups.map(group => group.props('messages').map(m => m.id))).toEqual(
      [[1], [3]]
    );
    expect(groups.map(group => group.props('isActive'))).toEqual([false, true]);
    expect(wrapper.findComponent(CopilotLoader).exists()).toBe(false);
    expect(
      wrapper.findComponent(CopilotReviewProgress).props('progress')
    ).toEqual(progress);
  });

  it.each([
    [
      'a running review',
      {
        message_type: 'assistant_progress',
        message: { progress: { finished: false } },
      },
      false,
    ],
    [
      'a finished review',
      {
        message_type: 'assistant_progress',
        message: { progress: { finished: true } },
      },
      true,
    ],
    [
      'a change being applied',
      {
        message_type: 'assistant_approval',
        message: { approval: { status: 'approved' } },
      },
      false,
    ],
    [
      'an old Copilot step',
      {
        message_type: 'assistant_thinking',
        message: { content: 'Completed search_documentation' },
      },
      true,
    ],
  ])(
    'shows the loader after %s only when nothing else shows progress',
    (_, last, isShown) => {
      const wrapper = mountComponent({
        messages: [
          { id: 1, message_type: 'user', message: { content: 'Hi' } },
          { id: 2, ...last },
        ],
      });

      expect(wrapper.findComponent(CopilotLoader).exists()).toBe(isShown);
    }
  );

  it('shows only the newest step while Copilot works on it', async () => {
    const wrapper = mount(CopilotThinkingGroup, {
      props: {
        isActive: true,
        messages: [
          { id: 1, message: { content: 'Searching contacts', run_id: 9 } },
          { id: 2, message: { content: 'Reading an article', run_id: 9 } },
        ],
      },
    });

    expect(wrapper.text()).toBe('Reading an article');
    expect(wrapper.findAllComponents(Spinner)).toHaveLength(1);

    await wrapper.find('button').trigger('click');

    expect(wrapper.findAll('button ~ div').map(row => row.text())).toEqual([
      'Searching contacts',
    ]);
  });

  it('warns on the live step when it failed', () => {
    const wrapper = mount(CopilotThinkingGroup, {
      props: {
        isActive: true,
        messages: [
          {
            id: 1,
            message: {
              content: 'Finding matching records',
              run_id: 9,
              status: 'failed',
            },
          },
        ],
      },
    });

    expect(wrapper.findAllComponents(Spinner)).toHaveLength(0);
    expect(wrapper.findAll('.i-lucide-triangle-alert')).toHaveLength(1);
  });

  it.each([
    [8, 'i-lucide-check'],
    [3, 'i-lucide-triangle-alert'],
  ])('marks a finished review with %i of 8 done', (done, icon) => {
    const wrapper = mount(CopilotReviewProgress, {
      props: {
        progress: { finished: true, done, total: 8, matched: 1, failed: 0 },
      },
    });

    expect(wrapper.find(`.${icon}`).exists()).toBe(true);
  });

  it('lists a repeated step once, where it last ran', async () => {
    const wrapper = mount(CopilotThinkingGroup, {
      props: {
        messages: [
          { id: 1, message: { content: 'Using search_documentation' } },
          step(2, 'Finding matching records'),
          step(3, 'Reading a conversation'),
          step(4, 'Finding matching records'),
        ],
      },
    });

    await wrapper.find('button').trigger('click');

    const rows = wrapper.findAll('button ~ div');
    expect(rows.map(row => row.text())).toEqual([
      'Using search_documentation',
      'Reading a conversation',
      'Finding matching records',
    ]);
    expect(wrapper.findAll('.i-lucide-sparkles')).toHaveLength(1);
    expect(wrapper.findAll('.i-lucide-check')).toHaveLength(2);
  });

  it('preserves a draft while a saved chat is loading', async () => {
    const wrapper = mount(Copilot, {
      props: {
        onSendMessage: vi.fn(),
        assistants: [{ id: 7, name: 'Support' }],
      },
      global: {
        mocks: { $t: key => key },
        stubs: {
          SidebarActionsHeader: true,
          CopilotEmptyState: true,
        },
      },
    });
    const input = wrapper.findComponent(CopilotInput);
    const textarea = input.find('textarea');

    await textarea.setValue('Keep this draft');
    await wrapper.setProps({ isLoadingSelectedThread: true });
    await wrapper.setProps({ isLoadingSelectedThread: false });

    expect(
      wrapper.findComponent(CopilotInput).find('textarea').element.value
    ).toBe('Keep this draft');
  });
});
