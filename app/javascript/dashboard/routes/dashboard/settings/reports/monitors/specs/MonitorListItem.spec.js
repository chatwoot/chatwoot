import { shallowMount } from '@vue/test-utils';
import MonitorListItem from '../MonitorListItem.vue';

const state = vi.hoisted(() => ({ push: vi.fn() }));
vi.mock('vue-router', async importOriginal => ({
  ...(await importOriginal()),
  useRouter: () => ({ push: state.push }),
}));
vi.mock('vue-i18n', async importOriginal => ({
  ...(await importOriginal()),
  useI18n: () => ({ t: key => key }),
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    accountScopedRoute: (name, params) => ({ name, params }),
  }),
}));

const monitor = {
  id: 3,
  name: 'Refunds',
  condition: 'Mentions refunds',
  recent_count: 12,
  paused_at: null,
};
const global = {
  stubs: { Button: false, RouterLink: { template: '<a><slot /></a>' } },
};

describe('MonitorListItem', () => {
  beforeEach(() => state.push.mockClear());

  it('emits the row actions without opening the monitor', async () => {
    const wrapper = shallowMount(MonitorListItem, {
      props: { monitor, showActions: true },
      global,
    });

    await wrapper.find('[aria-label="MONITORS.EDIT"]').trigger('click');
    await wrapper.find('[aria-label="MONITORS.PAUSE"]').trigger('click');
    await wrapper.find('[aria-label="MONITORS.DELETE"]').trigger('click');

    expect(wrapper.emitted('action')).toEqual([
      ['edit'],
      ['pause'],
      ['delete'],
    ]);
    expect(state.push).not.toHaveBeenCalled();
  });

  it('opens the monitor from anywhere on the row', async () => {
    const wrapper = shallowMount(MonitorListItem, {
      props: { monitor },
      global,
    });

    await wrapper.trigger('click');
    await wrapper.find('a').trigger('click');

    expect(state.push).toHaveBeenCalledOnce();
    expect(state.push).toHaveBeenCalledWith({
      name: 'monitor_reports_show',
      params: { monitorId: 3 },
    });
  });

  it('shows the monitor icon in its color and falls back to the monitor icon', async () => {
    const wrapper = shallowMount(MonitorListItem, {
      props: {
        monitor: { ...monitor, icon: 'fire-line', icon_color: '#EF4444' },
      },
      global,
    });

    expect(wrapper.findComponent({ name: 'EmojiIcon' }).props()).toMatchObject({
      value: 'fire-line',
      color: '#EF4444',
    });
    await wrapper.setProps({ monitor });
    expect(wrapper.findComponent({ name: 'EmojiIcon' }).exists()).toBe(false);
    expect(wrapper.findComponent({ name: 'Icon' }).props('icon')).toBe(
      'i-lucide-monitor'
    );
  });

  it('shows a paused monitor without actions for other roles', () => {
    const wrapper = shallowMount(MonitorListItem, {
      props: { monitor: { ...monitor, paused_at: 1790000000 } },
      global,
    });

    expect(wrapper.findComponent({ name: 'Label' }).props('label')).toBe(
      'MONITORS.STATES.PAUSED'
    );
    expect(wrapper.text()).toContain('MONITORS.LAST_DAYS_BEFORE_PAUSE');
    expect(wrapper.find('[aria-label]').exists()).toBe(false);
  });
});
