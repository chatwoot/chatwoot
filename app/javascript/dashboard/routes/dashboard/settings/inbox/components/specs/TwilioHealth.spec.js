import { mount } from '@vue/test-utils';
import TwilioHealth from '../TwilioHealth.vue';
import inboxMgmt from 'dashboard/i18n/locale/en/inboxMgmt.json';

const lookup = key =>
  key.split('.').reduce((node, part) => node?.[part], inboxMgmt);

// Resolve against the real English copy so a missing or renamed key fails the test.
const translate = (key, named = {}) =>
  String(lookup(key) ?? key).replace(
    /\{(\w+)\}/g,
    (match, name) => named[name] ?? match
  );

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, named) => translate(key, named),
    te: key => lookup(key) !== undefined,
  }),
}));

// Stand in for a white-labelled install so branded copy is verifiable.
vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({
    replaceInstallationName: text =>
      typeof text === 'string' ? text.replace(/chatwoot/gi, 'Acme Desk') : text,
  }),
}));

const ButtonStub = {
  template: '<button data-test="button"><slot /></button>',
};
const IconStub = {
  props: ['icon'],
  template: '<i :data-icon="icon" />',
};

const healthyData = {
  status: 'healthy',
  voice_enabled: false,
  account: {
    sid: 'AC123',
    friendly_name: 'Acme Support',
    status: 'active',
    type: 'Full',
  },
  sender: {
    type: 'phone_number',
    sid: 'PN123',
    label: '+15551234567',
    friendly_name: 'Support line',
    capabilities: { sms: true, mms: true, voice: false },
  },
  webhooks: [
    {
      name: 'messaging',
      expected: 'https://app.chatwoot.com/twilio/callback',
      actual: 'https://app.chatwoot.com/twilio/callback',
      method: 'POST',
      configured: true,
      reason: null,
    },
  ],
};

const withWebhook = overrides => ({
  ...healthyData,
  status: 'misconfigured',
  webhooks: [{ ...healthyData.webhooks[0], configured: false, ...overrides }],
});

const mountHealth = props =>
  mount(TwilioHealth, {
    props: { healthData: healthyData, ...props },
    global: {
      stubs: { ButtonV4: ButtonStub, Icon: IconStub, Spinner: true },
    },
  });

describe('TwilioHealth', () => {
  it('summarises a healthy inbox', () => {
    const wrapper = mountHealth();

    expect(wrapper.text()).toContain('All checks passed');
    expect(wrapper.text()).toContain('Acme Support');
    expect(wrapper.text()).toContain('+15551234567');
    expect(wrapper.text()).toContain('Webhook configured successfully');
    expect(wrapper.find('[data-test="button"]').exists()).toBe(true);
  });

  it('uses the installation name instead of ours in the health copy', () => {
    const wrapper = mountHealth({
      healthData: withWebhook({ reason: 'not_set', configured: false }),
    });

    expect(wrapper.text()).toContain('Acme Desk');
    expect(wrapper.text()).not.toContain('Chatwoot');
  });

  it('flags the account type so trial restrictions are visible', () => {
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        account: { ...healthyData.account, type: 'Trial' },
      },
    });

    expect(wrapper.text()).toContain('Trial');
    expect(wrapper.html()).toContain('text-n-amber-11');
  });

  it('marks a suspended account in red', () => {
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        account: { ...healthyData.account, status: 'suspended' },
      },
    });

    expect(wrapper.text()).toContain('Suspended');
    expect(wrapper.html()).toContain('text-n-ruby-11');
  });

  it('shows a missing required capability in red', () => {
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        voice_enabled: true,
        sender: {
          ...healthyData.sender,
          capabilities: { sms: true, mms: true, voice: false },
        },
      },
    });

    const chips = wrapper
      .findAll('span')
      .filter(node => ['SMS', 'MMS', 'Voice'].includes(node.text()));
    const classesFor = label =>
      chips
        .find(node => node.text() === label)
        .classes()
        .join(' ');

    // MMS is never required by Chatwoot, so it is not listed at all.
    expect(chips.map(node => node.text())).toEqual(['SMS', 'Voice']);
    expect(classesFor('SMS')).toContain('text-n-teal-11');
    expect(classesFor('Voice')).toContain('text-n-ruby-11');
  });

  it('greys out voice when the inbox does not use calling', () => {
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        voice_enabled: false,
        sender: {
          ...healthyData.sender,
          capabilities: { sms: true, voice: false },
        },
      },
    });

    const voice = wrapper.findAll('span').find(node => node.text() === 'Voice');

    expect(voice.classes().join(' ')).toContain('text-n-slate-11');
  });

  it('hides the account cards when a restricted key cannot read the account', () => {
    const wrapper = mountHealth({
      healthData: { ...healthyData, account: null },
    });

    const cardLabels = wrapper
      .findAll('.rounded-lg.border')
      .map(card => card.find('span').text());

    expect(cardLabels).not.toContain('Twilio account');
    expect(cardLabels).not.toContain('Account status');
    expect(cardLabels).not.toContain('Account type');
    // The webhook checks are the real signal and must survive.
    expect(cardLabels).toContain('Sender');
    expect(wrapper.text()).toContain('All checks passed');
    expect(wrapper.text()).toContain('Webhook configured successfully');
  });

  it('hides the capabilities card for a messaging service sender', () => {
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        sender: {
          type: 'messaging_service',
          sid: 'MG123',
          label: 'Acme Messaging',
        },
      },
    });

    expect(wrapper.text()).toContain('Acme Messaging');
    expect(wrapper.text()).toContain('Messaging service');
    expect(wrapper.text()).not.toContain('Number capabilities');
  });

  it.each([
    ['not_set', 'Webhook not configured'],
    ['url_mismatch', 'Webhook URL mismatch'],
    ['wrong_http_method', 'Webhook uses the wrong HTTP method'],
    ['overridden_by_number', 'Messaging service defers to the number'],
    ['overridden_by_application', 'Overridden by a TwiML app'],
    ['overridden_by_trunk', 'Overridden by a SIP trunk'],
    ['missing_twiml_app', 'TwiML app not created'],
  ])('states the real reason for %s', (reason, label) => {
    const wrapper = mountHealth({ healthData: withWebhook({ reason }) });

    expect(wrapper.text()).toContain('Needs attention');
    expect(wrapper.text()).toContain(label);
  });

  it('names the offending method when twilio calls us with GET', () => {
    const wrapper = mountHealth({
      healthData: withWebhook({ reason: 'wrong_http_method', method: 'GET' }),
    });

    expect(wrapper.text()).toContain(
      'Twilio calls it with GET instead of POST'
    );
  });

  it('offers to register a webhook we can fix ourselves', () => {
    const wrapper = mountHealth({
      healthData: withWebhook({ reason: 'url_mismatch' }),
    });

    // The console link plus the register button.
    expect(wrapper.findAll('[data-test="button"]')).toHaveLength(2);
  });

  it('shows one register button no matter how many webhooks are broken', () => {
    const broken = reason => ({
      ...healthyData.webhooks[0],
      configured: false,
      reason,
    });
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        status: 'misconfigured',
        webhooks: [
          { ...broken('url_mismatch'), name: 'messaging' },
          { ...broken('url_mismatch'), name: 'voice' },
          { ...broken('url_mismatch'), name: 'voice_status' },
          { ...broken('url_mismatch'), name: 'voice_app' },
        ],
      },
    });

    // Console link + a single Register webhooks action.
    const buttons = wrapper.findAll('[data-test="button"]');
    expect(buttons).toHaveLength(2);
    expect(buttons[1].text()).toBe('Register webhooks');
  });

  it('explains a shared failure once instead of per webhook', () => {
    const broken = name => ({
      ...healthyData.webhooks[0],
      name,
      configured: false,
      reason: 'url_mismatch',
    });
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        status: 'misconfigured',
        webhooks: [
          broken('messaging'),
          broken('voice'),
          broken('voice_status'),
        ],
      },
    });

    const hint =
      'Twilio is calling a different URL, so traffic goes elsewhere.';
    expect(wrapper.text().split(hint)).toHaveLength(2);
    // The per-webhook status pill still appears on every card.
    expect(wrapper.text().split('Webhook URL mismatch').length - 1).toBe(4);
  });

  it('explains each distinct failure when reasons differ', () => {
    const broken = (name, reason) => ({
      ...healthyData.webhooks[0],
      name,
      configured: false,
      reason,
    });
    const wrapper = mountHealth({
      healthData: {
        ...healthyData,
        status: 'misconfigured',
        webhooks: [
          broken('messaging', 'url_mismatch'),
          broken('voice', 'overridden_by_trunk'),
        ],
      },
    });

    expect(wrapper.text()).toContain(
      'Twilio is calling a different URL, so traffic goes elsewhere.'
    );
    expect(wrapper.text()).toContain('This number is attached to a SIP trunk');
  });

  it.each(['overridden_by_application', 'overridden_by_trunk'])(
    'does not offer to register when only the twilio console can fix it (%s)',
    reason => {
      const wrapper = mountHealth({ healthData: withWebhook({ reason }) });

      expect(wrapper.findAll('[data-test="button"]')).toHaveLength(1);
    }
  );

  it('emits registerWebhook when the button is pressed', async () => {
    const wrapper = mountHealth({
      healthData: withWebhook({ reason: 'not_set', actual: null }),
    });

    await wrapper.findAll('[data-test="button"]')[1].trigger('click');

    expect(wrapper.emitted('registerWebhook')).toHaveLength(1);
  });

  it('shows the provider error instead of an empty page', () => {
    const wrapper = mountHealth({
      healthData: null,
      error: '[HTTP 401] 20003 : Unable to fetch record',
    });

    expect(wrapper.text()).toContain('Could not reach Twilio');
    expect(wrapper.text()).toContain('[HTTP 401] 20003 : Unable to fetch');
  });

  it('shows a loading state rather than "not available" while fetching', () => {
    const wrapper = mountHealth({ healthData: null, isLoading: true });

    expect(wrapper.text()).toContain('Fetching health data from Twilio');
    expect(wrapper.text()).not.toContain('Health data is not available');
  });
});
