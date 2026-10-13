import { shallowMount } from '@vue/test-utils';

import Copilot from '../Copilot.vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';

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
  it('offers past chats and a new chat from the header', () => {
    const wrapper = mountComponent();
    const header = wrapper.findComponent(SidebarActionsHeader);

    expect(header.props('buttons').map(button => button.key)).toEqual([
      'history',
      'new',
    ]);
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
});
