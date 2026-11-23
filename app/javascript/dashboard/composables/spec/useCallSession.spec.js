import { createPinia, setActivePinia } from 'pinia';
import { useCallsStore } from 'dashboard/stores/calls';
import { useCallActions } from '../useCallSession';

const mocks = vi.hoisted(() => ({
  setHold: vi.fn(),
  setMuted: vi.fn(),
  setWhatsappCallOnHold: vi.fn(),
  setWhatsappMicMuted: vi.fn(),
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
  setWhatsappMicMuted: mocks.setWhatsappMicMuted,
  sendWhatsappTerminateBeacon: vi.fn(),
  cleanupWhatsappSession: vi.fn(),
}));

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

const mute = muted => useCallActions().muteCall({ callSid: 'CA1', muted });

beforeEach(() => {
  setActivePinia(createPinia());
  callsStore = useCallsStore();
  vi.clearAllMocks();
});

describe('muteCall', () => {
  it('mutes and unmutes the WhatsApp mic without holding the caller', () => {
    startCall('whatsapp');

    mute(true);

    expect(mocks.setWhatsappMicMuted).toHaveBeenCalledWith(true);
    expect(mocks.setMuted).not.toHaveBeenCalled();
    expect(callsStore.activeCall.isMuted).toBe(true);
    expect(callsStore.activeCall.onHold).toBe(false);

    mute(false);

    expect(mocks.setWhatsappMicMuted).toHaveBeenLastCalledWith(false);
    expect(callsStore.activeCall.isMuted).toBe(false);
  });

  it('mutes the Twilio agent leg without the hold API', () => {
    startCall('twilio');

    mute(true);

    expect(mocks.setMuted).toHaveBeenCalledWith(true);
    expect(mocks.setHold).not.toHaveBeenCalled();
    expect(callsStore.activeCall.isMuted).toBe(true);
  });

  it('leaves the mic alone for a call that is no longer active', () => {
    startCall('twilio');
    callsStore.clearActiveCall();

    mute(true);

    expect(mocks.setMuted).not.toHaveBeenCalled();
  });
});

describe('holdCall', () => {
  const hold = onHold =>
    useCallActions().holdCall({
      conversationId: 12,
      inboxId: 3,
      callSid: 'CA1',
      hold: onHold,
    });

  it('holds a WhatsApp caller in the browser without the Twilio API', async () => {
    startCall('whatsapp');

    await hold(true);

    expect(mocks.setWhatsappCallOnHold).toHaveBeenCalledWith(true, false);
    expect(mocks.setHold).not.toHaveBeenCalled();
    expect(mocks.setMuted).not.toHaveBeenCalled();
    expect(callsStore.activeCall.onHold).toBe(true);

    await hold(false);

    expect(mocks.setWhatsappCallOnHold).toHaveBeenLastCalledWith(false, false);
    expect(callsStore.activeCall.onHold).toBe(false);
  });

  it('resumes a muted WhatsApp call with the mic still muted', async () => {
    startCall('whatsapp');
    mute(true);

    await hold(true);
    await hold(false);

    expect(mocks.setWhatsappCallOnHold).toHaveBeenLastCalledWith(false, true);
    expect(callsStore.activeCall.isMuted).toBe(true);
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

    await hold(false);

    expect(mocks.setMuted).toHaveBeenLastCalledWith(false);
  });

  it('resumes a muted Twilio call with the agent leg still muted', async () => {
    startCall('twilio');
    mute(true);

    await hold(true);
    await hold(false);

    expect(mocks.setMuted).toHaveBeenLastCalledWith(true);
    expect(callsStore.activeCall.isMuted).toBe(true);
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
