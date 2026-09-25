import { shallowMount } from '@vue/test-utils';
import { ref } from 'vue';
import MonitorsEmptyState from '../MonitorsEmptyState.vue';

const state = vi.hoisted(() => ({ isAdmin: null }));
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: state.isAdmin }),
}));
vi.mock('vue-i18n', async importOriginal => ({
  ...(await importOriginal()),
  useI18n: () => ({ t: key => key }),
}));

describe('MonitorsEmptyState', () => {
  it('lets an administrator create a monitor or start from an example', async () => {
    state.isAdmin = ref(true);
    const wrapper = shallowMount(MonitorsEmptyState);

    wrapper.findComponent({ name: 'Button' }).vm.$emit('click');
    await wrapper.findAll('button')[1].trigger('click');

    expect(wrapper.emitted('create')).toEqual([
      [],
      [
        {
          name: 'MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.NAME',
          condition: 'MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.CONDITION',
        },
      ],
    ]);
    expect(wrapper.findAll('button')).toHaveLength(6);
    expect(wrapper.findAllComponents({ name: 'MonitorListItem' })).toHaveLength(
      3
    );
    expect(wrapper.text()).not.toContain('MONITORS.ADMIN_HELP');
  });

  it('shows the examples as disabled and asks other roles to contact an administrator', () => {
    state.isAdmin = ref(false);
    const wrapper = shallowMount(MonitorsEmptyState);

    expect(wrapper.findComponent({ name: 'Button' }).exists()).toBe(false);
    expect(wrapper.text()).toContain('MONITORS.ADMIN_HELP');
    expect(
      wrapper.findAll('button').every(button => button.element.disabled)
    ).toBe(true);
  });
});
