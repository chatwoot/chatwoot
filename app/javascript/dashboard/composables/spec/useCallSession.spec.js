import { createPinia, setActivePinia } from 'pinia';
import { useAlert } from 'dashboard/composables';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import { useCallSession } from '../useCallSession';

vi.mock('vue', async importOriginal => {
  const actual = await importOriginal();
  return {
    ...actual,
    onMounted: vi.fn(),
    onUnmounted: vi.fn(),
  };
});

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('dashboard/api/channel/voice/voiceAPIClient', () => ({
  default: {
    joinConference: vi.fn(),
    leaveConference: vi.fn(),
  },
}));

vi.mock('dashboard/api/channel/voice/twilioVoiceClient', () => ({
  default: {
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    initializeDevice: vi.fn(),
    joinClientCall: vi.fn(),
    endClientCall: vi.fn(),
  },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: vi.fn(key => key),
  }),
}));

describe('useCallSession', () => {
  let consoleErrorSpy;

  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  it('shows the backend conflict message when another agent already claimed the call', async () => {
    TwilioVoiceClient.initializeDevice.mockResolvedValue({ device: true });
    VoiceAPI.joinConference.mockRejectedValue({
      response: {
        data: {
          error: 'Jane Agent is already handling the call.',
        },
      },
    });

    const { joinCall } = useCallSession();
    const result = await joinCall({
      conversationId: 42,
      inboxId: 1,
      callSid: 'CALL123',
    });

    expect(result).toBeNull();
    expect(useAlert).toHaveBeenCalledWith(
      'Jane Agent is already handling the call.'
    );
    expect(TwilioVoiceClient.joinClientCall).not.toHaveBeenCalled();
  });
});
