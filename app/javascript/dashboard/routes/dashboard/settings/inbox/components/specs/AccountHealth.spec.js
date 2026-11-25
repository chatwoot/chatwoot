import { mount, shallowMount } from '@vue/test-utils';
import ButtonV4 from 'next/button/Button.vue';
import AccountHealth from '../AccountHealth.vue';

const { locale } = vi.hoisted(() => ({ locale: { value: 'en' } }));

// jsdom has no `navigator.clipboard`, so the copy button's handler rejects and the run exits 1
// even with every assertion green. The helper is the boundary this component talks to.
vi.mock('shared/helpers/clipboard', () => ({
  copyTextToClipboard: vi.fn(),
}));

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

  // `shallowMount` replaces ButtonV4 with a stub, and a stub renders no spinner no matter which
  // prop it receives, so an assertion about the operator seeing feedback would pass on the
  // broken code. This one mounts the real button.
  const mountDeep = (healthData, props = {}) =>
    mount(AccountHealth, {
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

  // Meta answers with the effective webhook configuration, and the chip above reads it as two
  // states: ours, or not ours. Both readings cover a number that owns its routing and a number
  // that owns none, which are different problems with different repairs.
  describe('when the number itself is not pointed at this installation', () => {
    const expectedUrl = 'https://chat.example.com/webhooks/whatsapp/+123';
    const elsewhereUrl = 'https://elsewhere.example.com/webhooks/whatsapp/+123';

    it('says so even though the card is green, because delivery rides on the app URL', () => {
      const wrapper = mountComponent({
        webhook_configuration: { application: expectedUrl },
        expected_webhook_url: expectedUrl,
        routed_by_app_callback_only: true,
      });

      expect(wrapper.text()).toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.RIDES_ON_APP_CALLBACK'
      );
    });

    // Meta routes at three levels, and only the third one belongs to the app. A WABA-level
    // override pointing here is this account's own routing: changing the app callback does not
    // touch it.
    it('stays quiet when the business account is the one pointed here', () => {
      const wrapper = mountComponent({
        webhook_configuration: {
          whatsapp_business_account: expectedUrl,
          application: elsewhereUrl,
        },
        expected_webhook_url: expectedUrl,
        routed_by_app_callback_only: false,
      });

      expect(wrapper.text()).not.toContain('APP_CALLBACK');
    });

    it('stays quiet when the override is in place for this number', () => {
      const wrapper = mountComponent({
        webhook_configuration: {
          phone_number: expectedUrl,
          application: elsewhereUrl,
        },
        expected_webhook_url: expectedUrl,
        routed_by_app_callback_only: false,
      });

      expect(wrapper.text()).not.toContain('APP_CALLBACK');
    });

    // An override of its own pointing at the wrong place is a mismatch the button above repairs:
    // registering rewrites that override. Saying anything about the app callback here would be
    // false, since the app callback is not what delivery follows.
    it('leaves the mismatch chip alone when the number has an override of its own', () => {
      const wrapper = mountComponent({
        webhook_configuration: {
          phone_number: elsewhereUrl,
          application: expectedUrl,
        },
        expected_webhook_url: expectedUrl,
        routed_by_app_callback_only: false,
      });

      expect(wrapper.text()).toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.URL_MISMATCH'
      );
      expect(wrapper.text()).not.toContain('APP_CALLBACK');
    });

    // The same chip, the other repair. With no override of its own, the URL on the card IS the
    // app callback: the button is writing an override that does not exist yet, which lands unless
    // Meta refuses it for this account, and only the press tells which. The sentence names the
    // app callback as the fallback, so the operator is not sent to a shared URL for a number the
    // button would have fixed.
    it('names the app callback as the fallback when it is what points elsewhere', () => {
      const wrapper = mountComponent({
        webhook_configuration: { application: elsewhereUrl },
        expected_webhook_url: expectedUrl,
        routed_by_app_callback_only: true,
      });

      expect(wrapper.text()).toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.URL_MISMATCH'
      );
      expect(wrapper.text()).toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.APP_CALLBACK_POINTS_ELSEWHERE'
      );
      // The sentence for a URL that still points here would be a lie about one that does not.
      expect(wrapper.text()).not.toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.RIDES_ON_APP_CALLBACK'
      );
    });

    // Nothing configured at all is the chip's own case, and its button is the repair.
    it('stays quiet when there is no webhook configuration to ride on', () => {
      const wrapper = mountComponent({
        webhook_configuration: {},
        expected_webhook_url: expectedUrl,
        routed_by_app_callback_only: true,
      });

      expect(wrapper.text()).toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.ACTION_REQUIRED'
      );
      expect(wrapper.text()).not.toContain('APP_CALLBACK');
    });
  });

  // Found by the verifier agent while measuring the screen for #588: the control that exists to
  // repair the webhook wiring left the screen exactly when the wiring was most likely to need
  // repairing. Presence is asserted through the event, not through markup: the only button on this
  // screen that asks for a registration is the one that emits it, whatever the layout does.
  describe('the register webhook control', () => {
    // Clicks every button on the screen and asks whether any of them asked for a registration.
    // The other buttons are harmless here (one opens a mocked window, one emits a navigation), and
    // this way the assertion survives any reshuffling of the markup.
    const clickRegisterWebhook = async wrapper => {
      await Promise.all(
        wrapper
          .findAllComponents(ButtonV4)
          .map(button => button.trigger('click'))
      );

      return Boolean(wrapper.emitted('registerWebhook'));
    };

    it('stays on the screen when the health read failed', async () => {
      const wrapper = mountComponent(null, {
        healthError: { type: 'api', message: 'Net::ReadTimeout' },
      });

      expect(await clickRegisterWebhook(wrapper)).toBe(true);
    });

    it('stays on the screen when the read failed on credentials, over the stale card', async () => {
      const wrapper = mountComponent(
        { webhook_configuration: { phone_number: 'https://old.example.com' } },
        {
          healthError: {
            type: 'authorization',
            message: 'Session has expired',
          },
          isEmbeddedSignup: true,
        }
      );

      expect(await clickRegisterWebhook(wrapper)).toBe(true);
    });

    it('is absent before the screen knows anything, which is not the same as a failed read', async () => {
      const wrapper = mountComponent(null);

      expect(await clickRegisterWebhook(wrapper)).toBe(false);
    });

    it('is absent when the webhook is configured and pointed here', async () => {
      const wrapper = mountComponent({
        webhook_configuration: {
          phone_number: 'https://app.example.com/webhooks/whatsapp/+1',
        },
        expected_webhook_url: 'https://app.example.com/webhooks/whatsapp/+1',
      });

      expect(await clickRegisterWebhook(wrapper)).toBe(false);
    });

    it('is present when the health read came back without a webhook configured', async () => {
      const wrapper = mountComponent({ webhook_configuration: {} });

      expect(await clickRegisterWebhook(wrapper)).toBe(true);
    });

    // The read failed, so the payload underneath is from a moment that has passed. It cannot be
    // read as "the webhook is fine" any more than it can be shown as the current routing.
    it('is present when the failed read sits on top of a payload that looked fine', async () => {
      const wrapper = mountComponent(
        {
          webhook_configuration: {
            phone_number: 'https://app.example.com/webhooks/whatsapp/+1',
          },
          expected_webhook_url: 'https://app.example.com/webhooks/whatsapp/+1',
        },
        { healthError: { type: 'api', message: 'Net::ReadTimeout' } }
      );

      expect(await clickRegisterWebhook(wrapper)).toBe(true);
    });

    // The POST it fires writes to Meta, so the second click has to find the control locked. The
    // lock is the `disabled` attribute: `loading` is not a prop of this button (the prop is
    // `isLoading`), so it falls through as an attribute and paints nothing, here and where this
    // control used to live.
    it('keeps the lock that stops a second registration from leaving', () => {
      const wrapper = mountComponent(null, {
        healthError: { type: 'api', message: 'Net::ReadTimeout' },
        isRegisteringWebhook: true,
      });

      const locked = wrapper
        .findAllComponents(ButtonV4)
        .filter(button => button.attributes('disabled') === 'true');

      expect(locked).toHaveLength(1);
    });

    // The attribute is on the element in both states, so asking whether it exists says only that
    // the binding was written. What has to be true is that it answers.
    it('does not lock the control when no registration is in flight', () => {
      const wrapper = mountComponent(null, {
        healthError: { type: 'api', message: 'Net::ReadTimeout' },
        isRegisteringWebhook: false,
      });

      const locked = wrapper
        .findAllComponents(ButtonV4)
        .filter(button => button.attributes('disabled') === 'true');

      expect(locked).toHaveLength(0);
    });

    // The button keeps its own name and explanation. What it must not bring along is the reading:
    // the chip and the URLs are claims about where delivery is going now, and there was no answer.
    it('carries its label but none of the lines built from a reading that did not happen', () => {
      const wrapper = mountComponent(
        {
          webhook_configuration: {
            phone_number: 'https://elsewhere.example.com/webhooks/whatsapp/+1',
          },
          expected_webhook_url: 'https://app.example.com/webhooks/whatsapp/+1',
        },
        { healthError: { type: 'api', message: 'Net::ReadTimeout' } }
      );

      expect(wrapper.text()).toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.TITLE'
      );
      expect(wrapper.text()).not.toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.URL_MISMATCH'
      );
      expect(wrapper.text()).not.toContain(
        'INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.CONFIGURED_SUCCESS'
      );
      expect(wrapper.text()).not.toContain(
        'https://elsewhere.example.com/webhooks/whatsapp/+1'
      );
    });
  });

  // The prop that draws the spinner is `isLoading`. A call site passing `loading` instead gets
  // no error: the name is not in the prop list and not in EXCLUDED_ATTRS, so it falls through
  // `useAttrs` onto the `<button>` element, where the browser ignores it. The registration writes
  // to Meta and can take the whole Graph ceiling to answer, so what the operator sees for those
  // seconds is a button that looks idle.
  describe('while the webhook registration is in flight', () => {
    const registering = {
      healthError: {
        type: 'generic',
        message: 'The health read did not answer',
      },
      isRegisteringWebhook: true,
    };

    // Two buttons render in this state and both are ButtonV4, so a lookup by component or by
    // `button[disabled]` picks whichever comes first in the tree and says nothing about the one
    // this is about. `isLoading` cannot be the discriminator either: it defaults to false, so
    // every button in the tree answers it.
    const registerButton = wrapper =>
      wrapper
        .findAll('button')
        .find(candidate =>
          candidate
            .text()
            .includes('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.REGISTER_BUTTON')
        );

    // Scoped to the button, not to the tree. Two ButtonV4 render in this state, so a tree-wide
    // `findComponent(Spinner)` is answered by either of them: moving the binding to the other
    // button leaves this suite at 48 green while the operator watches a spinner on the button
    // they did not click and gets nothing on the one they did, which is the defect this PR is
    // about. The lookup by button text is already here for exactly that reason a few lines up.
    it('draws the spinner on the register webhook button', () => {
      const wrapper = mountDeep(null, registering);

      expect(registerButton(wrapper)).toBeDefined();
      expect(registerButton(wrapper).find('svg.animate-spin').exists()).toBe(
        true
      );
    });

    it('does not leave the loading state on the element as an inert attribute', () => {
      const wrapper = mountDeep(null, registering);

      expect(registerButton(wrapper).attributes('loading')).toBeUndefined();
    });

    it('still disables that same button, which is the half that already worked', () => {
      const wrapper = mountDeep(null, registering);

      expect(registerButton(wrapper).attributes('disabled')).toBeDefined();
    });

    // The inert attribute shows up in both states, not only the busy one: a `false` bound to an
    // undeclared attribute renders as the string "false", which is truthy to nobody but is still
    // there in the markup. So the idle case discriminates the broken code from the fixed one on
    // its own, without having to reach the in-flight state at all.
    it('draws no spinner when nothing is in flight, and carries no attribute either', () => {
      const wrapper = mountDeep(null, {
        healthError: registering.healthError,
        isRegisteringWebhook: false,
      });

      expect(registerButton(wrapper)).toBeDefined();
      expect(registerButton(wrapper).find('svg.animate-spin').exists()).toBe(
        false
      );
      expect(registerButton(wrapper).attributes('loading')).toBeUndefined();
    });
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
