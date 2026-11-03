import VoiceAPI from '../voiceAPIClient';

describe('#VoiceAPI', () => {
  const originalAxios = window.axios;
  const axiosMock = { post: vi.fn(() => Promise.resolve({ data: {} })) };

  beforeEach(() => {
    window.axios = axiosMock;
  });

  afterEach(() => {
    window.axios = originalAxios;
  });

  it('#joinConference names the connection attempt it opens', () => {
    VoiceAPI.joinConference({
      conversationId: 7,
      inboxId: 3,
      callSid: 'CA1',
      attemptId: '1760000000-abc123',
    });

    expect(axiosMock.post).toHaveBeenCalledWith(
      expect.stringMatching(/\/inboxes\/3\/conference$/),
      { conversation_id: 7, call_sid: 'CA1', attempt_id: '1760000000-abc123' }
    );
  });
});
