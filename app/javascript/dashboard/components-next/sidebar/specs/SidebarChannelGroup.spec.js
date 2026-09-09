import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import SidebarChannelGroup from '../SidebarChannelGroup.vue';
import { provideSidebarContext } from '../provider';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref(1),
}));

vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({ shouldShow: () => true }),
}));

vi.mock('vue-router', () => ({
  useRouter: () => ({
    resolve: () => ({ path: '/' }),
    getRoutes: () => [],
  }),
}));

const children = [
  {
    name: 'WhatsApp Sales-1',
    label: 'WhatsApp Sales',
    to: { name: 'inbox_dashboard', params: { inbox_id: 1 } },
  },
  {
    name: 'Email-2',
    label: 'Email',
    to: { name: 'inbox_dashboard', params: { inbox_id: 2 } },
  },
];

const mountChannelGroup = ({ expandedChannelGroups = [], ...props } = {}) => {
  const toggleChannelGroup = vi.fn();

  const wrapper = mount(
    {
      components: { SidebarChannelGroup },
      setup() {
        provideSidebarContext({
          expandedChannelGroups: ref(expandedChannelGroups),
          toggleChannelGroup,
        });
      },
      template: '<SidebarChannelGroup v-bind="$attrs" />',
    },
    {
      attrs: {
        name: 'channel-group-1',
        label: 'Northstar',
        to: { name: 'channel_group_conversations' },
        children,
        badgeCount: 3,
        ...props,
      },
      global: {
        stubs: {
          RouterLink: { props: ['to'], template: '<a><slot /></a>' },
          SidebarGroupLeaf: {
            props: { label: { type: String, required: true } },
            template: '<li class="sidebar-leaf">{{ label }}</li>',
          },
        },
      },
    }
  );

  return { wrapper, toggleChannelGroup };
};

describe('SidebarChannelGroup', () => {
  it('hides its channels until the group is expanded', () => {
    const { wrapper } = mountChannelGroup();

    expect(wrapper.findAll('.sidebar-leaf')).toHaveLength(0);
    expect(wrapper.get('button').attributes('aria-expanded')).toBe('false');
  });

  it('lists its channels when expanded', () => {
    const { wrapper } = mountChannelGroup({
      expandedChannelGroups: ['channel-group-1'],
    });

    expect(wrapper.findAll('.sidebar-leaf').map(leaf => leaf.text())).toEqual([
      'WhatsApp Sales',
      'Email',
    ]);
  });

  it('toggles only the group it belongs to', async () => {
    const { wrapper, toggleChannelGroup } = mountChannelGroup();

    await wrapper.get('button').trigger('click');

    expect(toggleChannelGroup).toHaveBeenCalledWith('channel-group-1');
  });

  it('reports navigation so a collapsed sidebar popover can close', async () => {
    const { wrapper } = mountChannelGroup({
      expandedChannelGroups: ['channel-group-1'],
    });

    await wrapper.get('a').trigger('click');
    await wrapper.get('.sidebar-leaf').trigger('click');

    expect(
      wrapper.findComponent({ name: 'SidebarChannelGroup' }).emitted('navigate')
    ).toHaveLength(2);
  });

  it('shows the unread count of the group', () => {
    const { wrapper } = mountChannelGroup();

    expect(wrapper.get('[data-test-id="sidebar-unread-badge"]').text()).toBe(
      '3'
    );
  });

  it('marks the group active while one of its channels is open', () => {
    const { wrapper } = mountChannelGroup({ activeChild: children[1] });

    expect(wrapper.get('li > div').classes()).toContain('bg-n-alpha-2');
  });
});
