import { mount } from '@vue/test-utils';
import WhatsappCallingHealth from '../WhatsappCallingHealth.vue';

const { locale } = vi.hoisted(() => ({ locale: { value: 'en' } }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
    locale,
  }),
}));

const PREFIX = 'INBOX_MGMT.ACCOUNT_HEALTH.CALLING';

const mountComponent = calling =>
  mount(WhatsappCallingHealth, {
    props: {
      calling: {
        meta_status: { status: 'enabled' },
        webhook_subscription: { status: 'configured' },
        eligibility: { status: 'eligible', restrictions: [] },
        ...calling,
      },
    },
  });

describe('WhatsappCallingHealth', () => {
  it('shows every check as healthy without fix buttons', () => {
    const wrapper = mountComponent();

    expect(wrapper.text()).toContain(`${PREFIX}.STATUSES.ENABLED`);
    expect(wrapper.text()).toContain(`${PREFIX}.STATUSES.CONFIGURED`);
    expect(wrapper.text()).toContain(`${PREFIX}.STATUSES.ELIGIBLE`);
    expect(wrapper.findAll('button')).toHaveLength(0);
  });

  it('offers the fixes Chatwoot can make', async () => {
    const wrapper = mountComponent({
      meta_status: { status: 'disabled' },
      webhook_subscription: { status: 'missing', reason: 'app_not_subscribed' },
    });
    const [enableButton, registerButton] = wrapper.findAll('button');

    await enableButton.trigger('click');
    await registerButton.trigger('click');

    expect(wrapper.emitted('enableCalling')).toHaveLength(1);
    expect(wrapper.emitted('registerWebhook')).toHaveLength(1);
  });

  it('explains problems that need action at Meta', () => {
    const wrapper = mountComponent({
      meta_status: { status: 'unverified' },
      webhook_subscription: {
        status: 'missing',
        reason: 'calls_field_missing',
      },
      eligibility: {
        status: 'restricted',
        restrictions: [
          {
            type: 'RESTRICTED_USER_INITIATED_CALLING',
            expires_at: '2027-01-15T10:00:00Z',
          },
        ],
      },
    });

    expect(wrapper.text()).toContain(`${PREFIX}.UNVERIFIED_HINT`);
    expect(wrapper.text()).toContain(
      `${PREFIX}.WEBHOOK_SUBSCRIPTION.CALLS_FIELD_MISSING`
    );
    expect(wrapper.text()).toContain(
      `${PREFIX}.ELIGIBILITY.RESTRICTED_USER_INITIATED_CALLING`
    );
    expect(wrapper.findAll('button')).toHaveLength(0);
  });
});
