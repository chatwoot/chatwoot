import {
  cleanupWhatsappSession,
  sendWhatsappDigits,
  useWhatsappCallSession,
} from '../useWhatsappCallSession';

describe('sendWhatsappDigits', () => {
  let peerConnection;

  beforeEach(() => {
    const localTrack = { stop: vi.fn() };
    const localStream = {
      getTracks: vi.fn(() => [localTrack]),
    };
    const remoteStream = {
      addTrack: vi.fn(),
      getAudioTracks: vi.fn(() => []),
      getTracks: vi.fn(() => []),
    };

    peerConnection = {
      addTrack: vi.fn(),
      close: vi.fn(),
      createOffer: vi.fn().mockResolvedValue({ type: 'offer', sdp: 'offer' }),
      getSenders: vi.fn(() => []),
      iceGatheringState: 'complete',
      localDescription: null,
      setLocalDescription: vi.fn(async description => {
        peerConnection.localDescription = description;
      }),
    };

    vi.stubGlobal(
      'MediaStream',
      vi.fn(() => remoteStream)
    );
    vi.stubGlobal(
      'RTCPeerConnection',
      vi.fn(() => peerConnection)
    );
    vi.stubGlobal('navigator', {
      mediaDevices: {
        getUserMedia: vi.fn().mockResolvedValue(localStream),
      },
    });
  });

  afterEach(() => {
    cleanupWhatsappSession();
    vi.unstubAllGlobals();
  });

  it('returns false when there is no peer connection', () => {
    expect(sendWhatsappDigits('9')).toBe(false);
  });

  it('returns false when there is no audio sender and ignores video senders', async () => {
    const insertDTMF = vi.fn();
    peerConnection.getSenders.mockReturnValue([
      {
        track: { kind: 'video' },
        dtmf: { canInsertDTMF: true, insertDTMF, toneBuffer: '' },
      },
    ]);
    await useWhatsappCallSession().prepareOutboundOffer();

    expect(sendWhatsappDigits('9')).toBe(false);
    expect(insertDTMF).not.toHaveBeenCalled();
  });

  it('returns false when the audio sender has no DTMF support', async () => {
    peerConnection.getSenders.mockReturnValue([{ track: { kind: 'audio' } }]);
    await useWhatsappCallSession().prepareOutboundOffer();

    expect(sendWhatsappDigits('*')).toBe(false);
  });

  it('returns false when the audio sender cannot insert DTMF', async () => {
    const insertDTMF = vi.fn();
    peerConnection.getSenders.mockReturnValue([
      {
        track: { kind: 'audio' },
        dtmf: { canInsertDTMF: false, insertDTMF },
      },
    ]);
    await useWhatsappCallSession().prepareOutboundOffer();

    expect(sendWhatsappDigits('*')).toBe(false);
    expect(insertDTMF).not.toHaveBeenCalled();
  });

  it('appends a digit to buffered tones and inserts it once', async () => {
    const insertDTMF = vi.fn();
    peerConnection.getSenders.mockReturnValue([
      {
        track: { kind: 'audio' },
        dtmf: { canInsertDTMF: true, insertDTMF, toneBuffer: '12' },
      },
    ]);
    await useWhatsappCallSession().prepareOutboundOffer();

    expect(sendWhatsappDigits('#')).toBe(true);
    expect(insertDTMF).toHaveBeenCalledOnce();
    expect(insertDTMF).toHaveBeenCalledWith('12#', 500, 100);
  });

  it('returns false when insertion loses the WebRTC state race', async () => {
    const insertDTMF = vi.fn(() => {
      throw new DOMException('Peer connection closed', 'InvalidStateError');
    });
    peerConnection.getSenders.mockReturnValue([
      {
        track: { kind: 'audio' },
        dtmf: { canInsertDTMF: true, insertDTMF, toneBuffer: '' },
      },
    ]);
    await useWhatsappCallSession().prepareOutboundOffer();

    expect(sendWhatsappDigits('0')).toBe(false);
    expect(insertDTMF).toHaveBeenCalledOnce();
  });

  it('rethrows unrelated insertion errors', async () => {
    const insertionError = new Error('DTMF device failure');
    const insertDTMF = vi.fn(() => {
      throw insertionError;
    });
    peerConnection.getSenders.mockReturnValue([
      {
        track: { kind: 'audio' },
        dtmf: { canInsertDTMF: true, insertDTMF, toneBuffer: '' },
      },
    ]);
    await useWhatsappCallSession().prepareOutboundOffer();

    expect(() => sendWhatsappDigits('5')).toThrow(insertionError);
  });
});
