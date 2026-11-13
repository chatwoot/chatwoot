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
  const monaHealth = {
    verified_name: 'Mona',
    name_status: 'DECLINED',
    new_display_name: 'Mona Assistant',
    new_name_status: 'APPROVED',
    official_business_account: { oba_status: 'NOT_STARTED' },
    status: 'CONNECTED',
    is_on_biz_app: false,
  };

  it('groups the current and requested names with their statuses in one card', () => {
    const wrapper = mountComponent(monaHealth, { canManage: true });
    const cards = wrapper.findAll('[data-testid="display-name-card"]');
    expect(cards).toHaveLength(1);
    expect(cards[0].text()).toContain('Mona');
    expect(cards[0].text()).toContain('Mona Assistant');
    expect(cards[0].text()).toContain('Declined');
    expect(cards[0].text()).toContain('Approved');
    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ACCOUNT_HEALTH.DISPLAY_NAME.DESCRIPTIONS.APPROVED'
    );
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.ACCOUNT_HEALTH.FIELDS.DISPLAY_NAME_STATUS.DESCRIPTIONS.DECLINED'
    );
  });

  it('emits the displayed approved name when the administrator applies it', async () => {
    const wrapper = mountComponent(monaHealth, { canManage: true });
    const button = wrapper
      .findAllComponents(ButtonV4)
      .find(
        component =>
          component.attributes('data-testid') === 'apply-display-name'
      );
    await button.trigger('click');
    expect(wrapper.emitted('applyDisplayName')).toEqual([['Mona Assistant']]);
  });

  it.each(['PENDING_REVIEW', 'DECLINED', 'EXPIRED', 'NONE', undefined])(
    'does not offer registration for replacement status %s',
    status => {
      const wrapper = mountComponent(
        { ...monaHealth, new_name_status: status },
        { canManage: true }
      );
      expect(wrapper.find('[data-testid="apply-display-name"]').exists()).toBe(
        false
      );
    }
  );

  it.each([
    [{ ...monaHealth, is_on_biz_app: true }, { canManage: true }],
    [{ ...monaHealth, is_on_biz_app: undefined }, { canManage: true }],
    [{ ...monaHealth, status: 'DISCONNECTED' }, { canManage: true }],
    [monaHealth, { canManage: false }],
  ])(
    'does not offer registration for unsupported numbers or agents',
    (health, props) => {
      const wrapper = mountComponent(health, props);
      expect(wrapper.find('[data-testid="apply-display-name"]').exists()).toBe(
        false
      );
    }
  );

  it('disables the apply action while a request is in progress', () => {
    const wrapper = mountComponent(monaHealth, {
      canManage: true,
      isApplyingDisplayName: true,
    });
    const button = wrapper
      .findAllComponents(ButtonV4)
      .find(
        component =>
          component.attributes('data-testid') === 'apply-display-name'
      );
    expect(button.attributes('disabled')).toBeDefined();
    expect(button.props('isLoading')).toBe(true);
  });

  it.each(['APPROVED', 'PENDING', 'REJECTED', 'UNKNOWN', undefined])(
    'hides the apply action and explains the restriction for OBA status %s',
    status => {
      const wrapper = mountComponent(
        { ...monaHealth, official_business_account: { oba_status: status } },
        { canManage: true }
      );
      expect(wrapper.find('[data-testid="apply-display-name"]').exists()).toBe(
        false
      );
      expect(wrapper.text()).toContain('DISPLAY_NAME.OBA_RESTRICTED');
      expect(wrapper.text()).toContain('Mona Assistant');
    }
  );

  it('hides the apply action when OBA information is missing', () => {
    const wrapper = mountComponent(
      { ...monaHealth, official_business_account: undefined },
      { canManage: true }
    );
    expect(wrapper.find('[data-testid="apply-display-name"]').exists()).toBe(
      false
    );
    expect(wrapper.text()).toContain('DISPLAY_NAME.OBA_RESTRICTED');
  });

  it('removes the requested name section once the name has been activated', async () => {
    const wrapper = mountComponent(monaHealth, { canManage: true });
    await wrapper.setProps({
      healthData: {
        ...monaHealth,
        verified_name: 'Mona Assistant',
        name_status: 'APPROVED',
        new_display_name: null,
        new_name_status: 'NONE',
      },
    });
    expect(wrapper.text()).toContain('Mona Assistant');
    expect(wrapper.text()).toContain('DISPLAY_NAME.TITLE');
    expect(wrapper.text()).not.toContain('DISPLAY_NAME.REQUESTED_NAME');
    expect(wrapper.find('[data-testid="apply-display-name"]').exists()).toBe(
      false
    );
  });
});
