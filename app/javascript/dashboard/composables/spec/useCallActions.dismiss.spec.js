import { useCallActions } from 'dashboard/composables/useCallSession';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import WhatsappCallsAPI from 'dashboard/api/channel/whatsapp/whatsappCallsAPI';

const { callsStore } = vi.hoisted(() => ({
  callsStore: { calls: [], dismissCall: vi.fn() },
}));

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/stores/calls', () => ({ useCallsStore: () => callsStore }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/useWhatsappCallSession', () => ({
  useWhatsappCallSession: () => ({}),
  sendWhatsappTerminateBeacon: vi.fn(),
  cleanupWhatsappSession: vi.fn(),
}));
vi.mock('dashboard/api/channel/voice/twilioVoiceClient', () => ({
  default: { addEventListener: vi.fn(), removeEventListener: vi.fn() },
}));
vi.mock('dashboard/api/channel/voice/voiceAPIClient', () => ({
  default: { dismissRing: vi.fn() },
}));
vi.mock('dashboard/api/channel/whatsapp/whatsappCallsAPI', () => ({
  default: { dismiss: vi.fn() },
}));

describe('dismissing a ringing call', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    VoiceAPI.dismissRing.mockResolvedValue({});
    WhatsappCallsAPI.dismiss.mockResolvedValue({});
  });

  it('stops the ring for a WhatsApp call on the server, so it moves on to the next agent', async () => {
    callsStore.calls = [
      {
        callSid: 'wacid_1',
        callId: 9,
        provider: 'whatsapp',
        callDirection: 'inbound',
      },
    ];

    await useCallActions().dismissCall('wacid_1');

    expect(WhatsappCallsAPI.dismiss).toHaveBeenCalledWith(9);
    expect(VoiceAPI.dismissRing).not.toHaveBeenCalled();
    expect(callsStore.dismissCall).toHaveBeenCalledWith('wacid_1');
  });

  it('stops the ring for a Twilio call on the server', async () => {
    callsStore.calls = [
      {
        callSid: 'CA1',
        provider: 'twilio',
        callDirection: 'inbound',
        inboxId: 3,
        conversationId: 42,
      },
    ];

    await useCallActions().dismissCall('CA1');

    expect(VoiceAPI.dismissRing).toHaveBeenCalledWith({
      inboxId: 3,
      conversationId: 42,
      callSid: 'CA1',
    });
    expect(WhatsappCallsAPI.dismiss).not.toHaveBeenCalled();
  });

  it('keeps the card when the server could not dismiss it', async () => {
    WhatsappCallsAPI.dismiss.mockRejectedValue({ response: { status: 500 } });
    callsStore.calls = [
      {
        callSid: 'wacid_2',
        callId: 10,
        provider: 'whatsapp',
        callDirection: 'inbound',
      },
    ];

    await useCallActions().dismissCall('wacid_2');

    expect(callsStore.dismissCall).not.toHaveBeenCalled();
  });
});
