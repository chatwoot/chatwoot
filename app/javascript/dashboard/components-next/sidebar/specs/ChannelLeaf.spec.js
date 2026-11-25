import { mount } from '@vue/test-utils';
import { h, ref } from 'vue';
import ChannelLeaf from '../ChannelLeaf.vue';
import SidebarCollapsedPopover from '../SidebarCollapsedPopover.vue';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref(false),
}));

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn() }),
}));

vi.mock('../provider', () => ({
  useSidebarContext: () => ({
    isAllowed: () => true,
    sidebarWidth: ref(64),
  }),
}));

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
  it('renders the channel identifier beside the inbox name', () => {
    const wrapper = mountChannelLeaf({
      inbox: {
        channel_type: 'Channel::Email',
        email: 'support@example.com',
        reauthorization_required: false,
      },
    });

    expect(wrapper.text()).toContain('Website');
    expect(wrapper.text()).toContain('support@example.com');
    expect(
      wrapper.get('[data-test-id="channel-identifier"]').attributes('dir')
    ).toBe('auto');
  });

  it('exposes the name and identifier from the truncating container', () => {
    const wrapper = mountChannelLeaf({
      inbox: {
        channel_type: 'Channel::Email',
        email: 'support@example.com',
        reauthorization_required: false,
      },
    });

    expect(
      wrapper.get('[data-test-id="channel-leaf-label"]').attributes('title')
    ).toBe('Website \u00b7 support@example.com');
    expect(
      wrapper.get('[data-test-id="channel-identifier"]').attributes('title')
    ).toBeUndefined();
  });

  it('falls back to the inbox name when there is no identifier', () => {
    const wrapper = mountChannelLeaf({
      inbox: {
        channel_type: 'Channel::Email',
        reauthorization_required: false,
      },
    });

    expect(
      wrapper.get('[data-test-id="channel-leaf-label"]').attributes('title')
    ).toBe('Website');
  });

  it('keeps the current label when the channel has no identifier', () => {
    const wrapper = mountChannelLeaf({
      inbox: {
        channel_type: 'Channel::Email',
        reauthorization_required: false,
      },
    });

    expect(wrapper.text()).toBe('Website');
    expect(wrapper.find('[data-test-id="channel-identifier"]').exists()).toBe(
      false
    );
  });

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

  it('renders through the custom leaf in the collapsed sidebar popover', async () => {
    const inbox = {
      channel_type: 'Channel::Email',
      email: 'support@example.com',
      reauthorization_required: false,
    };
    const channel = {
      name: 'Website-1',
      label: 'Website',
      to: { name: 'inbox_dashboard' },
      component: leafProps =>
        h(ChannelLeaf, {
          label: leafProps.label,
          active: leafProps.active,
          badgeCount: leafProps.badgeCount,
          inbox,
        }),
    };
    const wrapper = mount(SidebarCollapsedPopover, {
      props: {
        label: 'Conversations',
        children: [
          {
            name: 'Channels',
            label: 'Channels',
            children: [channel],
          },
        ],
      },
      global: {
        mocks: {
          $t: key => key,
        },
        stubs: {
          ChannelIcon: true,
          Icon: true,
          TeleportWithDirection: {
            template: '<div><slot /></div>',
          },
        },
      },
    });

    await wrapper.get('button').trigger('click');

    expect(wrapper.text()).toContain('Website');
    expect(wrapper.text()).toContain('support@example.com');
  });
});
