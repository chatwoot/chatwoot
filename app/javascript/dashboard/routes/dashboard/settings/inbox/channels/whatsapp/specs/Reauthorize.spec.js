import { shallowMount } from '@vue/test-utils';
import Reauthorize from '../Reauthorize.vue';
import InboxReconnectionRequired from '../../../components/InboxReconnectionRequired.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

vi.mock('../utils', async importOriginal => ({
  ...(await importOriginal()),
  setupFacebookSdk: vi.fn().mockResolvedValue(),
}));

describe('WhatsApp Reauthorize', () => {
  const mountComponent = (providerConfig, props = {}) =>
    shallowMount(Reauthorize, {
      props: { inbox: { id: 1, provider_config: providerConfig }, ...props },
    });

  const bannerDescription = wrapper =>
    wrapper.findComponent(InboxReconnectionRequired).props('description');

  beforeEach(() => {
    window.chatwootConfig = {
      whatsappAppId: 'app-id',
      whatsappConfigurationId: 'config-id',
    };
  });

  it("explains Meta's reason when Meta removed access", () => {
    const wrapper = mountComponent({
      source: 'embedded_signup',
      disconnection_reason: 'PRIMARY_INACTIVITY',
    });

    expect(bannerDescription(wrapper)).toBe(
      'INBOX_MGMT.WHATSAPP_DISCONNECTION_REASON.PRIMARY_INACTIVITY'
    );
  });

  it('falls back to the default text for an unknown reason', () => {
    const wrapper = mountComponent({
      source: 'embedded_signup',
      disconnection_reason: 'SOMETHING_NEW',
    });

    expect(bannerDescription(wrapper)).toBe('');
  });

  it('keeps the registration message ahead of the reason', () => {
    const wrapper = mountComponent(
      { source: 'embedded_signup', disconnection_reason: 'PRIMARY_INACTIVITY' },
      { whatsappRegistrationIncomplete: true }
    );

    expect(bannerDescription(wrapper)).toBe(
      'INBOX_MGMT.WHATSAPP_REGISTRATION_INCOMPLETE'
    );
  });
});
