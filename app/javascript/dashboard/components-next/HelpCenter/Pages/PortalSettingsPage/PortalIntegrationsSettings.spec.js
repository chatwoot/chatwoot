import { mount } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import PortalIntegrationsSettings from './PortalIntegrationsSettings.vue';

vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  return {
    useStore: () => ({ getters: { 'inboxes/getInboxes': [] } }),
    useMapGetter: () => ref(() => ({ isUpdating: false })),
  };
});
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: true }),
}));
vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({ replaceInstallationName: value => value }),
}));

withFullI18n('da');

describe('Danish portal analytics translations', () => {
  it('preserves the same GA4 example in the placeholder and validation error', async () => {
    const wrapper = mount(PortalIntegrationsSettings, {
      props: { activePortal: { id: 1, slug: 'locale-qa', config: {} } },
      global: {
        stubs: {
          ComboBox: true,
          IntegrationCard: { template: '<section><slot /></section>' },
        },
      },
    });
    const measurementId = wrapper.find('input[placeholder="G-XXXXXXXXXX"]');
    expect(measurementId.exists()).toBe(true);

    await measurementId.setValue('invalid');
    expect(wrapper.text()).toContain(
      'Angiv et gyldigt måle-ID, for eksempel G-XXXXXXXXXX.'
    );
    expect(wrapper.find('button').attributes('disabled')).toBeDefined();

    await measurementId.setValue('G-ABC123XYZ9');
    expect(wrapper.text()).not.toContain('Angiv et gyldigt måle-ID');
    expect(wrapper.find('button').attributes('disabled')).toBeUndefined();
    await wrapper.find('button').trigger('click');
    expect(wrapper.emitted('updatePortalConfiguration')[0][0]).toEqual({
      id: 1,
      slug: 'locale-qa',
      inbox_id: '',
      config: { analytics: { ga4_measurement_id: 'G-ABC123XYZ9' } },
    });
    wrapper.unmount();
  });
});
