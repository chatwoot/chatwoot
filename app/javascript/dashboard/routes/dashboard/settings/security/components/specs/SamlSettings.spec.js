import { flushPromises, shallowMount } from '@vue/test-utils';
import NextButton from 'next/button/Button.vue';
import SamlInfoSection from '../SamlInfoSection.vue';
import SamlSettings from '../SamlSettings.vue';

const mocks = vi.hoisted(() => ({
  copyTextToClipboard: vi.fn(),
  samlSettingsAPI: {
    get: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
  useAlert: vi.fn(),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: mocks.useAlert,
}));

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    accountId: { value: 1 },
    isCloudFeatureEnabled: () => true,
  }),
}));

vi.mock('dashboard/api/samlSettings', () => ({
  default: mocks.samlSettingsAPI,
}));

vi.mock('shared/helpers/clipboard', () => ({
  copyTextToClipboard: mocks.copyTextToClipboard,
}));

describe('SamlSettings', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('keeps the SP certificate returned after saving', async () => {
    mocks.samlSettingsAPI.get.mockResolvedValue({
      data: {
        id: 1,
        sso_url: 'https://idp.example.com/saml/sso',
        sls_url: 'https://idp.example.com/saml/slo',
        certificate: 'idp-certificate',
        idp_entity_id: 'https://idp.example.com/saml',
        sp_certificate: 'initial-sp-certificate',
      },
    });
    mocks.samlSettingsAPI.update.mockResolvedValue({
      data: {
        id: 1,
        sp_certificate: 'generated-sp-certificate',
      },
    });

    const wrapper = shallowMount(SamlSettings, {
      global: {
        stubs: {
          SectionLayout: {
            template: '<div><slot name="headerActions" /><slot /></div>',
          },
        },
      },
    });
    await flushPromises();

    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(mocks.samlSettingsAPI.update).toHaveBeenCalledOnce();
    expect(wrapper.findComponent(SamlInfoSection).props('spCertificate')).toBe(
      'generated-sp-certificate'
    );
  });

  it('displays and copies the SP certificate', async () => {
    const spCertificate = '-----BEGIN CERTIFICATE----- SP data';
    const wrapper = shallowMount(SamlInfoSection, {
      props: { spCertificate },
    });

    expect(wrapper.text()).toContain(spCertificate);

    const copyButtons = wrapper.findAllComponents(NextButton);
    await copyButtons.at(-1).trigger('click');

    expect(mocks.copyTextToClipboard).toHaveBeenCalledWith(spCertificate);
  });
});
