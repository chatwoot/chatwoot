import ConfigurationPage from '../ConfigurationPage.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const showWhatsAppReconfigure = options =>
  ConfigurationPage.computed.showWhatsAppReconfigure.call({
    inbox: {
      provider_config: { source: 'embedded_signup' },
      reauthorization_required: false,
    },
    isEmbeddedSignupWhatsApp: true,
    accountId: 1,
    isFeatureEnabledonAccount: () => false,
    ...options,
  });

describe('ConfigurationPage', () => {
  it('shows reconfiguration when an embedded signup inbox requires reauthorization', () => {
    expect(
      showWhatsAppReconfigure({
        inbox: {
          provider_config: { source: 'embedded_signup' },
          reauthorization_required: true,
        },
      })
    ).toBe(true);
  });

  it('keeps reconfiguration feature-gated for a healthy inbox', () => {
    const isFeatureEnabledonAccount = vi.fn(() => false);

    expect(showWhatsAppReconfigure({ isFeatureEnabledonAccount })).toBe(false);
    expect(isFeatureEnabledonAccount).toHaveBeenCalledWith(
      1,
      FEATURE_FLAGS.WHATSAPP_EMBEDDED_SIGNUP_FLOW
    );
  });
});
