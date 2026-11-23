import { mount } from '@vue/test-utils';
import WhatsappCallingHealth from '../WhatsappCallingHealth.vue';

const { locale } = vi.hoisted(() => ({ locale: { value: 'en' } }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, named) => (named ? `${key} ${JSON.stringify(named)}` : key),
    te: key => !key.endsWith('.UNKNOWN_TYPE'),
    locale,
  }),
}));

const PREFIX = 'INBOX_MGMT.ACCOUNT_HEALTH.CALLING';

const healthyCalling = {
  meta_status: { status: 'enabled' },
  webhook_subscription: { status: 'configured' },
  eligibility: { status: 'eligible', restrictions: [] },
};

describe('WhatsappCallingHealth', () => {
  const mountComponent = (calling = {}) =>
    mount(WhatsappCallingHealth, {
      props: { calling: { ...healthyCalling, ...calling } },
    });

  it('shows every check as healthy without fix buttons', () => {
    const wrapper = mountComponent();

    expect(wrapper.text()).toContain(`${PREFIX}.META_STATUS.ENABLED`);
    expect(wrapper.text()).toContain(
      `${PREFIX}.WEBHOOK_SUBSCRIPTION.CONFIGURED`
    );
    expect(wrapper.text()).toContain(`${PREFIX}.ELIGIBILITY.ELIGIBLE`);
    expect(wrapper.findAll('button')).toHaveLength(0);
  });

  it('offers to enable calling when Meta has it disabled', async () => {
    const wrapper = mountComponent({ meta_status: { status: 'disabled' } });

    expect(wrapper.text()).toContain(`${PREFIX}.META_STATUS.DISABLED_HINT`);
    await wrapper.find('button').trigger('click');

    expect(wrapper.emitted('enableCalling')).toHaveLength(1);
  });

  it('offers to re-register the webhook when the app is not subscribed', async () => {
    const wrapper = mountComponent({
      webhook_subscription: { status: 'missing', reason: 'app_not_subscribed' },
    });

    expect(wrapper.text()).toContain(
      `${PREFIX}.WEBHOOK_SUBSCRIPTION.HINTS.APP_NOT_SUBSCRIBED`
    );
    await wrapper.find('button').trigger('click');

    expect(wrapper.emitted('registerWebhook')).toHaveLength(1);
  });

  it('explains a missing calls field without a fix button', () => {
    const wrapper = mountComponent({
      webhook_subscription: {
        status: 'missing',
        reason: 'calls_field_missing',
      },
    });

    expect(wrapper.text()).toContain(
      `${PREFIX}.WEBHOOK_SUBSCRIPTION.HINTS.CALLS_FIELD_MISSING`
    );
    expect(wrapper.findAll('button')).toHaveLength(0);
  });

  it('lists restrictions with their expiry, falling back to the raw type', () => {
    const wrapper = mountComponent({
      eligibility: {
        status: 'restricted',
        restrictions: [
          {
            type: 'RESTRICTED_USER_INITIATED_CALLING',
            expires_at: '2027-01-15T10:00:00Z',
          },
          { type: 'UNKNOWN_TYPE', expires_at: null },
        ],
      },
    });

    expect(wrapper.text()).toContain(`${PREFIX}.ELIGIBILITY.RESTRICTED`);
    expect(wrapper.text()).toContain(
      `${PREFIX}.ELIGIBILITY.TYPES.RESTRICTED_USER_INITIATED_CALLING ${PREFIX}.ELIGIBILITY.EXPIRES`
    );
    expect(wrapper.text()).toContain('UNKNOWN_TYPE');
    expect(wrapper.text()).toContain(`${PREFIX}.ELIGIBILITY.RESTRICTION_HINT`);
  });

  it('shows "Unable to verify" for checks Meta did not return', () => {
    const wrapper = mountComponent({
      meta_status: { status: 'unverified' },
      eligibility: { status: 'unverified' },
    });

    expect(
      wrapper
        .findAll('span')
        .filter(span => span.text() === `${PREFIX}.UNVERIFIED`)
    ).toHaveLength(2);
    expect(wrapper.text()).toContain(`${PREFIX}.UNVERIFIED_HINT`);
    expect(wrapper.findAll('button')).toHaveLength(0);
  });
});
