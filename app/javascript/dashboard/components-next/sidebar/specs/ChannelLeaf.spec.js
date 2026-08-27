import { mount } from '@vue/test-utils';
import ChannelLeaf from '../ChannelLeaf.vue';

const mountChannelLeaf = props =>
  mount(ChannelLeaf, {
    props: {
      label: 'Website',
      inbox: { reauthorization_required: false },
      ...props,
    },
    global: {
      mocks: {
        $t: key => key,
      },
      stubs: {
        ChannelIcon: true,
        Icon: true,
      },
    },
  });

describe('ChannelLeaf', () => {
  it('renders unread badge when count is present', () => {
    const wrapper = mountChannelLeaf({ badgeCount: 3 });
    const badge = wrapper.find('[data-test-id="sidebar-unread-badge"]');

    expect(badge.exists()).toBe(true);
    expect(badge.text()).toBe('3');
  });

  it('does not render unread badge when count is zero', () => {
    const wrapper = mountChannelLeaf({ badgeCount: 0 });

    expect(wrapper.find('[data-test-id="sidebar-unread-badge"]').exists()).toBe(
      false
    );
  });
});
