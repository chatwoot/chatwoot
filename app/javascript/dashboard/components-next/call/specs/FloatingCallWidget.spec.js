import { computed, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import CallCard from '../CallCard.vue';

const mocks = vi.hoisted(() => ({
  activeCall: null,
  sendDigits: vi.fn(),
  sendWhatsappDigits: vi.fn(),
  useAlert: vi.fn(),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { accountId: '1' } }),
  useRouter: () => ({ push: vi.fn() }),
}));

vi.mock('vuex', () => ({
  useStore: () => ({
    getters: {
      getConversationById: vi.fn(() => ({
        inbox_id: 7,
        meta: {
          sender: {
            name: 'Apartment intercom',
            phone_number: '+16045550198',
          },
        },
      })),
      'inboxes/getInbox': vi.fn(() => ({ name: 'Voice' })),
    },
  }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: mocks.useAlert,
}));

vi.mock('dashboard/composables/useCallSession', () => ({
  useCallSession: () => ({
    activeCall: computed(() => mocks.activeCall),
    incomingCalls: ref([]),
    hasActiveCall: computed(() => Boolean(mocks.activeCall)),
    isJoining: ref(false),
    joinCall: vi.fn(),
    endCall: vi.fn(),
    rejectIncomingCall: vi.fn(),
    dismissCall: vi.fn(),
    formattedCallDuration: ref('00:42'),
  }),
}));

vi.mock('dashboard/composables/useWhatsappCallSession', () => ({
  sendWhatsappDigits: mocks.sendWhatsappDigits,
  setWhatsappCallMuted: vi.fn(),
}));

vi.mock('dashboard/api/channel/voice/twilioVoiceClient', () => ({
  default: {
    sendDigits: mocks.sendDigits,
    setMuted: vi.fn(),
  },
}));

import FloatingCallWidget from '../FloatingCallWidget.vue';

const activeCall = provider => ({
  callSid: 'CA123',
  conversationId: 42,
  inboxId: 7,
  ...(provider ? { provider } : {}),
  isActive: true,
});

const mountWidget = () =>
  mount(FloatingCallWidget, {
    global: {
      stubs: { Avatar: true, Icon: true },
    },
  });

describe('FloatingCallWidget keypad', () => {
  beforeEach(() => {
    vi.spyOn(HTMLMediaElement.prototype, 'pause').mockImplementation(() => {});
    mocks.activeCall = activeCall(VOICE_CALL_PROVIDERS.TWILIO);
    mocks.sendDigits.mockReturnValue(true);
    mocks.sendWhatsappDigits.mockReturnValue(true);
  });

  it('exposes the keypad and routes digits only to Twilio for an active Twilio call', async () => {
    const wrapper = mountWidget();
    const keypadToggle = wrapper.find(
      '[data-test-id="voice-call-keypad-toggle"]'
    );

    expect(keypadToggle.exists()).toBe(true);

    await keypadToggle.trigger('click');
    await wrapper.find('[data-digit="9"]').trigger('click');

    expect(mocks.sendDigits).toHaveBeenCalledWith('9');
    expect(mocks.sendWhatsappDigits).not.toHaveBeenCalled();
  });

  it('exposes the keypad and routes digits only to WhatsApp for an active WhatsApp call', async () => {
    mocks.activeCall = activeCall(VOICE_CALL_PROVIDERS.WHATSAPP);
    const wrapper = mountWidget();
    const keypadToggle = wrapper.find(
      '[data-test-id="voice-call-keypad-toggle"]'
    );

    expect(keypadToggle.exists()).toBe(true);

    await keypadToggle.trigger('click');
    await wrapper.find('[data-digit="3"]').trigger('click');

    expect(mocks.sendWhatsappDigits).toHaveBeenCalledWith('3');
    expect(mocks.sendDigits).not.toHaveBeenCalled();
  });

  it('does not expose the keypad for an unsupported provider', () => {
    mocks.activeCall = activeCall('unsupported');
    const wrapper = mountWidget();

    expect(
      wrapper.find('[data-test-id="voice-call-keypad-toggle"]').exists()
    ).toBe(false);
  });

  it.each([
    { providerName: 'unsupported', provider: 'unsupported' },
    { providerName: 'missing', provider: undefined },
  ])(
    'does not route digits for a $providerName provider',
    async ({ provider }) => {
      mocks.activeCall = activeCall(provider);
      const wrapper = mountWidget();

      expect(
        wrapper.find('[data-test-id="voice-call-keypad-toggle"]').exists()
      ).toBe(false);

      wrapper.findComponent(CallCard).vm.$emit('sendDigit', '5');
      await wrapper.vm.$nextTick();

      expect(mocks.sendDigits).not.toHaveBeenCalled();
      expect(mocks.sendWhatsappDigits).not.toHaveBeenCalled();
      expect(mocks.useAlert).not.toHaveBeenCalled();
    }
  );

  it.each([
    {
      providerName: 'Twilio',
      provider: VOICE_CALL_PROVIDERS.TWILIO,
      sendMethod: 'sendDigits',
    },
    {
      providerName: 'WhatsApp',
      provider: VOICE_CALL_PROVIDERS.WHATSAPP,
      sendMethod: 'sendWhatsappDigits',
    },
  ])(
    'alerts when the $providerName connection cannot send the digit',
    async ({ provider, sendMethod }) => {
      mocks.activeCall = activeCall(provider);
      mocks[sendMethod].mockReturnValue(false);
      const wrapper = mountWidget();
      await wrapper
        .find('[data-test-id="voice-call-keypad-toggle"]')
        .trigger('click');
      await wrapper.find('[data-digit="#"]').trigger('click');

      expect(mocks.useAlert).toHaveBeenCalledOnce();
      expect(mocks.useAlert).toHaveBeenCalledWith('Could not send keypad tone');
    }
  );
});
