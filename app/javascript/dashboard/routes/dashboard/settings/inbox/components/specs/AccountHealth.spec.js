import { shallowMount } from '@vue/test-utils';
import ButtonV4 from 'next/button/Button.vue';
import AccountHealth from '../AccountHealth.vue';

const { locale } = vi.hoisted(() => ({ locale: { value: 'en' } }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
    te: () => false,
    locale,
  }),
}));

describe('AccountHealth', () => {
  const mountComponent = (healthData, props = {}) =>
    shallowMount(AccountHealth, {
      props: { healthData, ...props },
    });

  beforeEach(() => {
    locale.value = 'en';
    vi.spyOn(window, 'open').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('opens the phone numbers page for the correct WhatsApp Business Account', async () => {
    const wrapper = mountComponent({
      business_account_id: 'waba-456',
      business_portfolio_id: 'business-123',
    });

    await wrapper.findComponent(ButtonV4).trigger('click');

    expect(window.open).toHaveBeenCalledWith(
      'https://business.facebook.com/latest/whatsapp_manager/phone_numbers/?business_id=business-123&asset_id=waba-456',
      '_blank'
    );
  });

  it('opens Meta Business Manager when the WhatsApp Business Account ID is unavailable', async () => {
    const wrapper = mountComponent({
      business_portfolio_id: 'business-123',
    });

    await wrapper.findComponent(ButtonV4).trigger('click');

    expect(window.open).toHaveBeenCalledWith(
      'https://business.facebook.com/',
      '_blank'
    );
  });

  it('formats unknown messaging tiers and account modes without exposing translation keys', () => {
    const wrapper = mountComponent({
      messaging_limit_tier: 'TIER_CUSTOM',
      account_mode: 'CUSTOM_MODE',
    });

    expect(wrapper.text()).toContain('Tier Custom');
    expect(wrapper.text()).toContain('Custom Mode');
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.ACCOUNT_HEALTH.VALUES.TIERS.TIER_CUSTOM'
    );
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.ACCOUNT_HEALTH.VALUES.MODES.CUSTOM_MODE'
    );
  });

  it('formats dates for underscore-based locales', () => {
    locale.value = 'pt_BR';

    const wrapper = mountComponent({
      last_onboarded_time: '2026-05-29T20:11:58+0000',
    });

    expect(wrapper.text()).toContain('2026');
  });

  it('renders multiple business profile websites on separate lines', () => {
    const expectedWebsites =
      'https://business.test\nhttps://docs.business.test';
    const wrapper = mountComponent({
      business_profile: {
        websites: expectedWebsites.split('\n'),
      },
    });

    const websites = wrapper
      .findAll('span')
      .find(element => element.text() === expectedWebsites);

    expect(websites).toBeDefined();
  });

  it('shows specific guidance for an expired display name status', () => {
    const wrapper = mountComponent({ name_status: 'EXPIRED' });

    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.DESCRIPTIONS.EXPIRED'
    );
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.DESCRIPTIONS.UNKNOWN'
    );
  });

  it('shows the current error instead of stale health data', () => {
    const wrapper = mountComponent(
      { verified_name: 'Stale Business Name' },
      {
        healthError: {
          type: 'authorization',
          message: 'The connection needs to be refreshed',
        },
        isEmbeddedSignup: true,
      }
    );

    expect(wrapper.text()).toContain('The connection needs to be refreshed');
    expect(wrapper.text()).not.toContain('Stale Business Name');
  });
});
