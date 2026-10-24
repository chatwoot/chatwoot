import { mount, shallowMount } from '@vue/test-utils';

import Copilot from '../Copilot.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import ToggleCopilotAssistant from '../ToggleCopilotAssistant.vue';
import CopilotInput from '../CopilotInput.vue';
import CopilotThinkingGroup from '../CopilotThinkingGroup.vue';
import CopilotReviewProgress from '../CopilotReviewProgress.vue';
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

  it('shows a review progress card between the steps groups', () => {
    const progress = { finished: false, done: 5, total: 300, matched: 1 };
    const step = (id, content) => ({
      id,
      message_type: 'assistant_thinking',
      message: { content },
    });
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
    expect(
      wrapper.findComponent(CopilotReviewProgress).props('progress')
    ).toEqual(progress);
  });

  it('keeps the old Copilot step icon and marks workflow steps', () => {
    const wrapper = mount(CopilotThinkingGroup, {
      props: {
        isActive: true,
        messages: [
          { id: 1, message: { content: 'Using search_documentation' } },
          { id: 2, message: { content: 'Searching contacts', run_id: 9 } },
          { id: 3, message: { content: 'Reading an article', run_id: 9 } },
        ],
      },
    });

    expect(wrapper.findAll('.i-lucide-sparkles')).toHaveLength(1);
    expect(wrapper.findAll('.i-lucide-check')).toHaveLength(1);
    expect(wrapper.findAllComponents(Spinner)).toHaveLength(1);
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
