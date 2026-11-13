import { ref } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import SidebarChannelGroup from '../SidebarChannelGroup.vue';
import SidebarCollapsedPopover from '../SidebarCollapsedPopover.vue';
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

describe('channel groups in the collapsed sidebar', () => {
  const mountPopover = (activeChild = undefined) => {
    const group = {
      name: 'channel-group-1',
      label: 'Northstar',
      to: { name: 'channel_group_conversations' },
      children,
    };
    const expandedChannelGroups = ref([]);
    const wrapper = mount(
      {
        components: { SidebarCollapsedPopover },
        setup() {
          provideSidebarContext({
            sidebarWidth: ref(56),
            expandedChannelGroups,
            toggleChannelGroup: name => {
              expandedChannelGroups.value = [name];
            },
          });
        },
        template: '<SidebarCollapsedPopover v-bind="$attrs" />',
      },
      {
        attrs: {
          label: 'Conversations',
          children: [
            { name: 'Channels', label: 'Channels', children: [group] },
          ],
          activeChild,
        },
        global: {
          stubs: {
            TeleportWithDirection: { template: '<div><slot /></div>' },
            RouterLink: { props: ['to'], template: '<a><slot /></a>' },
            SidebarSortMenu: true,
            SidebarGroupLeaf: {
              props: { label: { type: String, required: true } },
              template: '<li class="sidebar-leaf">{{ label }}</li>',
            },
          },
        },
      }
    );
    return { wrapper, popover: wrapper.findComponent(SidebarCollapsedPopover) };
  };

  it('renders and expands a group with the same props as the expanded sidebar', async () => {
    const { wrapper, popover } = mountPopover();
    await popover.get('button').trigger('click');
    const group = popover.findComponent(SidebarChannelGroup);
    expect(group.exists()).toBe(true);
    expect(group.props('name')).toBe('channel-group-1');
    await group.get('button').trigger('click');
    expect(group.findAll('.sidebar-leaf').map(leaf => leaf.text())).toEqual([
      'WhatsApp Sales',
      'Email',
    ]);
    await group.get('a').trigger('click');
    expect(popover.emitted('close')).toHaveLength(1);
    wrapper.unmount();
  });

  it('opens the Channels section and marks the group active for a member route', async () => {
    const { wrapper, popover } = mountPopover(children[1]);
    await flushPromises();
    const group = popover.findComponent(SidebarChannelGroup);
    expect(group.exists()).toBe(true);
    expect(group.get('li > div').classes()).toContain('bg-n-alpha-2');
    wrapper.unmount();
  });
});
