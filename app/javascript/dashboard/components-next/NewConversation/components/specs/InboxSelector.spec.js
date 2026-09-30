import { mount } from '@vue/test-utils';
import InboxSelector from '../InboxSelector.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const targetInbox = {
  name: 'Support',
  email: 'support@example.com',
  channelType: INBOX_TYPES.EMAIL,
};

const mountSelector = (props = {}) =>
  mount(InboxSelector, {
    props: { targetInbox, showInboxesDropdown: false, ...props },
  });

describe('InboxSelector', () => {
  it('shows the selected inbox with a remove button by default', async () => {
    const wrapper = mountSelector();

    expect(wrapper.text()).toContain('Support (support@example.com)');
    await wrapper.findComponent(Button).trigger('click');
    expect(wrapper.emitted('updateInbox')).toEqual([[null]]);
  });

  it('hides the remove button when the inbox is not removable', () => {
    const wrapper = mountSelector({ removable: false });

    expect(wrapper.text()).toContain('Support (support@example.com)');
    expect(wrapper.findComponent(Button).exists()).toBe(false);
  });
});
