import {
  cleanupWhatsappSession,
  isWhatsappCallConnected,
  sendWhatsappDigits,
  setWhatsappCallOnHold,
  setWhatsappMicMuted,
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
      connectionState: 'new',
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

  it('tracks the peer connection and clears readiness when it disconnects or is cleaned up', async () => {
    await useWhatsappCallSession().prepareOutboundOffer();
    expect(isWhatsappCallConnected.value).toBe(false);

    peerConnection.connectionState = 'connected';
    peerConnection.onconnectionstatechange();
    expect(isWhatsappCallConnected.value).toBe(true);

    peerConnection.connectionState = 'disconnected';
    peerConnection.onconnectionstatechange();
    expect(isWhatsappCallConnected.value).toBe(false);

    peerConnection.connectionState = 'connected';
    peerConnection.onconnectionstatechange();
    expect(isWhatsappCallConnected.value).toBe(true);
    cleanupWhatsappSession();
    expect(isWhatsappCallConnected.value).toBe(false);
    peerConnection.onconnectionstatechange();
    expect(isWhatsappCallConnected.value).toBe(false);
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

describe('setWhatsappCallOnHold', () => {
  let micTrack;
  let musicTrack;
  let sender;
  let peerConnection;
  let audioContexts;

  beforeEach(() => {
    micTrack = { kind: 'audio', enabled: true, stop: vi.fn() };
    musicTrack = { kind: 'audio' };
    sender = {
      track: micTrack,
      replaceTrack: vi.fn(async track => {
        sender.track = track;
      }),
    };
    const localStream = {
      getAudioTracks: vi.fn(() => [micTrack]),
      getTracks: vi.fn(() => [micTrack]),
    };
    peerConnection = {
      addTrack: vi.fn(),
      close: vi.fn(),
      createOffer: vi.fn().mockResolvedValue({ type: 'offer', sdp: 'offer' }),
      getSenders: vi.fn(() => [sender]),
      iceGatheringState: 'complete',
      setLocalDescription: vi.fn(async description => {
        peerConnection.localDescription = description;
      }),
    };
    audioContexts = [];
    const source = { connect: vi.fn(), start: vi.fn() };

    vi.stubGlobal(
      'AudioContext',
      vi.fn(() => {
        const context = {
          createBufferSource: vi.fn(() => source),
          createMediaStreamDestination: vi.fn(() => ({
            stream: { getAudioTracks: () => [musicTrack] },
          })),
          decodeAudioData: vi.fn().mockResolvedValue('buffer'),
          resume: vi.fn().mockResolvedValue(),
          close: vi.fn().mockResolvedValue(),
        };
        audioContexts.push(context);
        return context;
      })
    );
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({ arrayBuffer: () => new ArrayBuffer(8) })
    );
    vi.stubGlobal(
      'MediaStream',
      vi.fn(() => ({ getTracks: () => [], getAudioTracks: () => [] }))
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

  it('sends looping hold music in place of the muted mic, then restores the mic on resume', async () => {
    await useWhatsappCallSession().prepareOutboundOffer();

    await setWhatsappCallOnHold(true);

    expect(fetch).toHaveBeenCalledWith('/audio/dashboard/hold-music.mp3');
    expect(sender.replaceTrack).toHaveBeenLastCalledWith(musicTrack);
    expect(micTrack.enabled).toBe(false);
    expect(audioContexts[0].createBufferSource().loop).toBe(true);

    await setWhatsappCallOnHold(false);

    expect(sender.replaceTrack).toHaveBeenLastCalledWith(micTrack);
    expect(micTrack.enabled).toBe(true);
    expect(audioContexts[0].close).toHaveBeenCalledOnce();
  });

  it('resumes a muted call with the mic still muted', async () => {
    await useWhatsappCallSession().prepareOutboundOffer();
    setWhatsappMicMuted(true);

    await setWhatsappCallOnHold(true);
    await setWhatsappCallOnHold(false, true);

    expect(sender.replaceTrack).toHaveBeenLastCalledWith(micTrack);
    expect(micTrack.enabled).toBe(false);
  });

  it('mutes and unmutes the mic without swapping the sent track', async () => {
    await useWhatsappCallSession().prepareOutboundOffer();

    setWhatsappMicMuted(true);
    expect(micTrack.enabled).toBe(false);

    setWhatsappMicMuted(false);
    expect(micTrack.enabled).toBe(true);
    expect(sender.replaceTrack).not.toHaveBeenCalled();
  });

  it('reuses the playing music when the hold is repeated', async () => {
    await useWhatsappCallSession().prepareOutboundOffer();

    await setWhatsappCallOnHold(true);
    await setWhatsappCallOnHold(true);

    expect(audioContexts).toHaveLength(1);
    expect(sender.replaceTrack).toHaveBeenLastCalledWith(musicTrack);
  });

  it('stops the music when the call ends while held', async () => {
    await useWhatsappCallSession().prepareOutboundOffer();
    await setWhatsappCallOnHold(true);

    cleanupWhatsappSession();

    expect(audioContexts[0].close).toHaveBeenCalledOnce();
  });

  it('drops the music when the call ends while it loads', async () => {
    await useWhatsappCallSession().prepareOutboundOffer();

    const hold = setWhatsappCallOnHold(true);
    cleanupWhatsappSession();
    await hold;

    expect(sender.replaceTrack).not.toHaveBeenCalled();
    expect(audioContexts[0].close).toHaveBeenCalledOnce();
  });

  it('keeps the mic live when the music fails to load', async () => {
    fetch.mockRejectedValue(new Error('offline'));
    await useWhatsappCallSession().prepareOutboundOffer();

    await expect(setWhatsappCallOnHold(true)).rejects.toThrow('offline');

    expect(sender.replaceTrack).not.toHaveBeenCalled();
    expect(micTrack.enabled).toBe(true);
    expect(audioContexts[0].close).toHaveBeenCalledOnce();
  });

  it('keeps the mic live and drops the music when the track swap fails', async () => {
    sender.replaceTrack.mockRejectedValue(new Error('swap failed'));
    await useWhatsappCallSession().prepareOutboundOffer();

    await expect(setWhatsappCallOnHold(true)).rejects.toThrow('swap failed');

    expect(micTrack.enabled).toBe(true);
    expect(audioContexts[0].close).toHaveBeenCalledOnce();

    sender.replaceTrack.mockResolvedValue();
    await setWhatsappCallOnHold(true);
    expect(audioContexts).toHaveLength(2);
  });

  it('rejects when there is no live call', async () => {
    await expect(setWhatsappCallOnHold(true)).rejects.toThrow();
  });
});
