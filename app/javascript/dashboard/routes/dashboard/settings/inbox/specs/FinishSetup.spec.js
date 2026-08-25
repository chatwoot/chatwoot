import { computed } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import FinishSetup from '../FinishSetup.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const mocks = vi.hoisted(() => ({
  inbox: {},
  toDataURL: vi.fn(),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { inbox_id: 1 } }),
}));

vi.mock('vuex', () => ({
  useStore: () => ({
    getters: {
      'inboxes/getInbox': () => mocks.inbox,
      'inboxes/getFacebookInboxByInstagramId': () => null,
    },
  }),
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: key => {
    if (key === 'inboxes/getInboxById') {
      return computed(() => () => mocks.inbox);
    }

    return computed(() => null);
  },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('qrcode', () => ({
  default: { toDataURL: mocks.toDataURL },
}));

const mountComponent = () =>
  mount(FinishSetup, {
    global: {
      renderStubDefaultSlot: true,
      mocks: { $t: key => key, $route: { params: { inbox_id: 1 } } },
      stubs: {
        EmptyState: { template: '<div><slot /></div>' },
        RouterLink: { template: '<div><slot /></div>' },
        NextButton: true,
        DuplicateInboxBanner: true,
        EmailInboxFinish: true,
        'woot-code': {
          props: ['script'],
          template: '<pre data-testid="callback-url">{{ script }}</pre>',
        },
      },
    },
  });

describe('FinishSetup', () => {
  beforeEach(() => {
    mocks.inbox = {};
    mocks.toDataURL.mockReset();
    mocks.toDataURL.mockResolvedValue('data:image/png;base64,qr');
  });

  it('does not show SMS setup guidance for a Twilio voice inbox', async () => {
    mocks.inbox = {
      channel_type: INBOX_TYPES.TWILIO,
      medium: 'sms',
      voice_enabled: true,
      phone_number: '+15555550100',
      callback_webhook_url: 'https://example.com/twilio/callback',
    };

    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.FINISH.SMS_QR_INSTRUCTION'
    );
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.FINISH.TWILIO_CALLBACK_FALLBACK'
    );
    expect(mocks.toDataURL).not.toHaveBeenCalledWith('sms:+15555550100');
  });

  it('shows QR and callback fallback guidance for Twilio SMS', async () => {
    mocks.inbox = {
      channel_type: INBOX_TYPES.TWILIO,
      medium: 'sms',
      voice_enabled: false,
      phone_number: '+15555550100',
      callback_webhook_url: 'https://example.com/twilio/callback',
    };

    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain('INBOX_MGMT.FINISH.SMS_QR_INSTRUCTION');
    expect(wrapper.text()).toContain(
      'INBOX_MGMT.FINISH.TWILIO_CALLBACK_FALLBACK'
    );
    expect(wrapper.get('img').attributes('alt')).toBe(
      'INBOX_MGMT.FINISH.SMS_QR_ALT'
    );
  });

  it('shows QR and callback fallback guidance for Twilio WhatsApp', async () => {
    mocks.inbox = {
      channel_type: INBOX_TYPES.TWILIO,
      medium: 'whatsapp',
      phone_number: 'whatsapp:+15555550100',
      callback_webhook_url: 'https://example.com/twilio/callback',
    };

    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain(
      'INBOX_MGMT.FINISH.WHATSAPP_QR_INSTRUCTION'
    );
    expect(wrapper.text()).toContain(
      'INBOX_MGMT.FINISH.TWILIO_CALLBACK_FALLBACK'
    );
  });

  it('keeps manual callback guidance for Bandwidth SMS', async () => {
    mocks.inbox = {
      channel_type: INBOX_TYPES.SMS,
      callback_webhook_url: 'https://example.com/bandwidth/callback',
    };

    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ADD.SMS.BANDWIDTH.API_CALLBACK.TITLE'
    );
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.FINISH.TWILIO_CALLBACK_FALLBACK'
    );
  });

  it('keeps manual webhook details primary for WhatsApp Cloud', async () => {
    mocks.inbox = {
      channel_type: INBOX_TYPES.WHATSAPP,
      provider: 'whatsapp_cloud',
      provider_config: { webhook_verify_token: 'verify-token' },
      callback_webhook_url: 'https://example.com/whatsapp/callback',
      phone_number: '+15555550100',
    };

    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain(
      'INBOX_MGMT.ADD.WHATSAPP.API_CALLBACK.WEBHOOK_URL'
    );
    expect(wrapper.text()).not.toContain(
      'INBOX_MGMT.FINISH.TWILIO_CALLBACK_FALLBACK'
    );
  });
});
