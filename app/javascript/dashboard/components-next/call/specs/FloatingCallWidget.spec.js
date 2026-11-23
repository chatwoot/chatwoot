import { withFullI18n } from 'test-i18n';
import { computed, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import CallCard from '../CallCard.vue';

const mocks = vi.hoisted(() => ({
  activeCall: null,
  twilioConnected: null,
  whatsappConnected: null,
  sendDigits: vi.fn(),
  sendWhatsappDigits: vi.fn(),
  holdCall: vi.fn(),
  muteCall: vi.fn(),
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
    muteCall: mocks.muteCall,
    holdCall: mocks.holdCall,
    formattedCallDuration: ref('00:42'),
  }),
}));

vi.mock('dashboard/composables/useWhatsappCallSession', async () => {
  const { ref: createRef } = await import('vue');
  mocks.whatsappConnected = createRef(false);
  return {
    isWhatsappCallConnected: mocks.whatsappConnected,
    sendWhatsappDigits: mocks.sendWhatsappDigits,
  };
});

vi.mock('dashboard/api/channel/voice/twilioVoiceClient', async () => {
  const { ref: createRef } = await import('vue');
  mocks.twilioConnected = createRef(false);
  return {
    isTwilioCallConnected: mocks.twilioConnected,
    default: {
      sendDigits: mocks.sendDigits,
      setMuted: vi.fn(),
    },
  };
});

import FloatingCallWidget from '../FloatingCallWidget.vue';

const activeCall = provider => ({
  callSid: 'CA123',
  conversationId: 42,
  inboxId: 7,
  ...(provider ? { provider } : {}),
  isActive: true,
  status: 'in-progress',
});

const mountWidget = () =>
  mount(FloatingCallWidget, {
    global: {
      stubs: { Avatar: true, Icon: true },
    },
  });

withFullI18n();

describe('FloatingCallWidget keypad', () => {
  beforeEach(() => {
    vi.spyOn(HTMLMediaElement.prototype, 'pause').mockImplementation(() => {});
    mocks.activeCall = activeCall(VOICE_CALL_PROVIDERS.TWILIO);
    mocks.twilioConnected.value = true;
    mocks.whatsappConnected.value = true;
    mocks.sendDigits.mockReturnValue(true);
    mocks.sendWhatsappDigits.mockReturnValue(true);
  });

  it.each([
    { provider: VOICE_CALL_PROVIDERS.TWILIO, state: 'twilioConnected' },
    { provider: VOICE_CALL_PROVIDERS.WHATSAPP, state: 'whatsappConnected' },
  ])(
    'waits for the $provider connection and closes the keypad when it drops',
    async ({ provider, state }) => {
      mocks.activeCall = activeCall(provider);
      mocks[state].value = false;
      const wrapper = mountWidget();
      const toggle = () =>
        wrapper.find('[data-test-id="voice-call-keypad-toggle"]');

      expect(toggle().exists()).toBe(false);
      wrapper.findComponent(CallCard).vm.$emit('sendDigit', '1');
      expect(mocks.sendDigits).not.toHaveBeenCalled();
      expect(mocks.sendWhatsappDigits).not.toHaveBeenCalled();

      mocks[state].value = true;
      await wrapper.vm.$nextTick();
      expect(toggle().exists()).toBe(true);
      await toggle().trigger('click');
      expect(wrapper.find('#voice-call-keypad').exists()).toBe(true);

      mocks[state].value = false;
      await wrapper.vm.$nextTick();
      expect(toggle().exists()).toBe(false);
      expect(wrapper.find('#voice-call-keypad').exists()).toBe(false);

      mocks[state].value = true;
      await wrapper.vm.$nextTick();
      expect(toggle().exists()).toBe(true);
      expect(wrapper.find('#voice-call-keypad').exists()).toBe(false);
    }
  );

  it('keeps the keypad hidden while the outbound contact rings even when the Twilio media leg is open', () => {
    mocks.activeCall = {
      ...activeCall(VOICE_CALL_PROVIDERS.TWILIO),
      status: 'ringing',
    };
    const wrapper = mountWidget();

    expect(
      wrapper.find('[data-test-id="voice-call-keypad-toggle"]').exists()
    ).toBe(false);
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

describe('FloatingCallWidget mute and hold', () => {
  const PROVIDERS = [
    VOICE_CALL_PROVIDERS.TWILIO,
    VOICE_CALL_PROVIDERS.WHATSAPP,
  ];

  beforeEach(() => {
    vi.spyOn(HTMLMediaElement.prototype, 'pause').mockImplementation(() => {});
    mocks.holdCall.mockReset().mockResolvedValue();
    mocks.muteCall.mockReset();
  });

  it.each(PROVIDERS)('mutes a %s call without holding it', provider => {
    mocks.activeCall = activeCall(provider);
    const card = mountWidget().findComponent(CallCard);

    expect(card.props('isMuted')).toBe(false);
    card.vm.$emit('toggleMute');

    expect(mocks.muteCall).toHaveBeenCalledWith({
      callSid: 'CA123',
      muted: true,
    });
    expect(mocks.holdCall).not.toHaveBeenCalled();
  });

  it.each(PROVIDERS)('unmutes a muted %s call', provider => {
    mocks.activeCall = { ...activeCall(provider), isMuted: true };
    const card = mountWidget().findComponent(CallCard);

    expect(card.props('isMuted')).toBe(true);
    card.vm.$emit('toggleMute');

    expect(mocks.muteCall).toHaveBeenCalledWith({
      callSid: 'CA123',
      muted: false,
    });
  });

  it.each(PROVIDERS)('puts a %s caller on hold from hold', provider => {
    mocks.activeCall = activeCall(provider);
    const card = mountWidget().findComponent(CallCard);

    card.vm.$emit('toggleHold');

    expect(mocks.holdCall).toHaveBeenCalledWith({
      conversationId: 42,
      inboxId: 7,
      callSid: 'CA123',
      hold: true,
    });
    expect(mocks.muteCall).not.toHaveBeenCalled();
  });

  it.each(PROVIDERS)('resumes a held %s caller', provider => {
    mocks.activeCall = { ...activeCall(provider), onHold: true };
    const card = mountWidget().findComponent(CallCard);

    card.vm.$emit('toggleHold');

    expect(mocks.holdCall).toHaveBeenCalledWith(
      expect.objectContaining({ callSid: 'CA123', hold: false })
    );
  });
});
