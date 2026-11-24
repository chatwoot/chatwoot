import { createPinia, setActivePinia } from 'pinia';
import { useCallsStore } from 'dashboard/stores/calls';
import { useCallActions } from '../useCallSession';

const mocks = vi.hoisted(() => ({
  setHold: vi.fn(),
  setMuted: vi.fn(),
  setWhatsappCallOnHold: vi.fn(),
  useAlert: vi.fn(),
}));

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: mocks.useAlert }));
vi.mock('dashboard/api/channel/voice/voiceAPIClient', () => ({
  default: { setHold: mocks.setHold },
}));
vi.mock('dashboard/api/channel/voice/twilioVoiceClient', () => ({
  default: { setMuted: mocks.setMuted, endClientCall: vi.fn() },
}));
vi.mock('dashboard/composables/useWhatsappCallSession', () => ({
  useWhatsappCallSession: () => ({}),
  setWhatsappCallOnHold: mocks.setWhatsappCallOnHold,
  sendWhatsappTerminateBeacon: vi.fn(),
  cleanupWhatsappSession: vi.fn(),
}));

describe('holdCall', () => {
  let callsStore;

  const startCall = provider => {
    callsStore.addCall({
      callSid: 'CA1',
      conversationId: 12,
      inboxId: 3,
      provider,
    });
    callsStore.setCallActive('CA1');
  };
  const hold = onHold =>
    useCallActions().holdCall({
      conversationId: 12,
      inboxId: 3,
      callSid: 'CA1',
      hold: onHold,
    });

  beforeEach(() => {
    setActivePinia(createPinia());
    callsStore = useCallsStore();
  });

  it('holds a WhatsApp caller in the browser without the Twilio API', async () => {
    startCall('whatsapp');

    await hold(true);

    expect(mocks.setWhatsappCallOnHold).toHaveBeenCalledWith(true);
    expect(mocks.setHold).not.toHaveBeenCalled();
    expect(mocks.setMuted).not.toHaveBeenCalled();
    expect(callsStore.activeCall.onHold).toBe(true);

    await hold(false);

    expect(mocks.setWhatsappCallOnHold).toHaveBeenLastCalledWith(false);
    expect(callsStore.activeCall.onHold).toBe(false);
  });

  it('holds a Twilio caller through the API and mutes the agent leg', async () => {
    startCall('twilio');

    await hold(true);

    expect(mocks.setHold).toHaveBeenCalledWith({
      inboxId: 3,
      conversationId: 12,
      callSid: 'CA1',
      hold: true,
    });
    expect(mocks.setMuted).toHaveBeenCalledWith(true);
    expect(mocks.setWhatsappCallOnHold).not.toHaveBeenCalled();
    expect(callsStore.activeCall.onHold).toBe(true);
  });

  it('keeps a WhatsApp call off hold and alerts when the hold fails', async () => {
    startCall('whatsapp');
    mocks.setWhatsappCallOnHold.mockRejectedValue(new Error('offline'));

    await hold(true);

    expect(callsStore.activeCall.onHold).toBe(false);
    expect(mocks.useAlert).toHaveBeenCalledWith(
      'CONVERSATION.VOICE_WIDGET.HOLD_FAILED'
    );
  });
});
