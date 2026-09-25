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

const refundTemplate = {
  id: 'refund-requests',
  name: 'Refund requests',
  condition: 'Customers asking for money back',
  icon: 'money-dollar-circle-line',
  icon_color: '#8B5CF6',
};

describe('MonitorsEmptyState', () => {
  it('offers the refund template and a link to all templates', async () => {
    state.isAdmin = ref(true);
    const wrapper = shallowMount(MonitorsEmptyState, {
      props: { template: refundTemplate },
    });

    const card = wrapper.findComponent({ name: 'MonitorTemplateCard' });
    expect(card.props('template')).toEqual(refundTemplate);
    expect(card.props('canCreate')).toBe(true);
    card.vm.$emit('use', refundTemplate);
    await wrapper.find('button').trigger('click');

    expect(wrapper.emitted('create')).toEqual([[refundTemplate]]);
    expect(wrapper.emitted('browse')).toEqual([[]]);
  });

  it('lets other roles browse while keeping template creation unavailable', () => {
    state.isAdmin = ref(false);
    const wrapper = shallowMount(MonitorsEmptyState, {
      props: { template: refundTemplate },
    });

    expect(
      wrapper.findComponent({ name: 'MonitorTemplateCard' }).props('canCreate')
    ).toBe(false);
    expect(wrapper.text()).toContain('MONITORS.ADMIN_HELP');
    expect(wrapper.find('button').element.disabled).toBe(false);
  });
});
