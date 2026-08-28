import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import WhatsappCallsAPI from 'dashboard/api/channel/whatsapp/whatsappCallsAPI';
import {
  useWhatsappCallSession,
  cleanupWhatsappSession,
} from '../useWhatsappCallSession';

vi.mock('dashboard/api/channel/whatsapp/whatsappCallsAPI', () => ({
  default: {
    show: vi.fn(),
    accept: vi.fn(),
    terminate: vi.fn(),
    uploadRecording: vi.fn(),
  },
}));

const SDP_OFFER = 'v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\n';
const CALL_ID = 42;

const audioTrack = { kind: 'audio', stop: vi.fn() };

const buildMediaStream = (tracks = []) => ({
  addTrack: track => tracks.push(track),
  getTracks: () => tracks,
  getAudioTracks: () => tracks.filter(t => t.kind === 'audio'),
});

// Emits one chunk as soon as it starts, so the upload path downstream of the
// recording gate has something to send.
const buildMediaRecorder = recorders => {
  const recorder = {
    state: 'inactive',
    ondataavailable: null,
    stopHandler: null,
    addEventListener: (event, handler) => {
      if (event === 'stop') recorder.stopHandler = handler;
    },
    start: () => {
      recorder.state = 'recording';
      recorder.ondataavailable?.({
        data: new Blob(['chunk'], { type: 'audio/webm' }),
      });
    },
    stop: () => {
      recorder.state = 'inactive';
      recorder.stopHandler?.();
    },
  };
  recorders.push(recorder);
  return recorder;
};

const buildPeerConnection = () => ({
  iceGatheringState: 'complete',
  localDescription: { sdp: 'answer-sdp' },
  ontrack: null,
  addTrack: () => {},
  addEventListener: () => {},
  getSenders: () => [],
  close: () => {},
  createAnswer: () => Promise.resolve({ type: 'answer', sdp: 'answer-sdp' }),
  setLocalDescription: () => Promise.resolve(),
  // Meta's offer landing is what fires ontrack in the real browser.
  setRemoteDescription() {
    this.ontrack?.({
      streams: [buildMediaStream([audioTrack])],
      track: audioTrack,
    });
    return Promise.resolve();
  },
});

describe('useWhatsappCallSession recording gate', () => {
  let recorders;

  beforeEach(() => {
    recorders = [];
    const mediaRecorder = vi.fn(() => buildMediaRecorder(recorders));
    mediaRecorder.isTypeSupported = () => true;

    vi.stubGlobal('MediaRecorder', mediaRecorder);
    vi.stubGlobal(
      'MediaStream',
      vi.fn(() => buildMediaStream([]))
    );
    vi.stubGlobal('RTCPeerConnection', vi.fn(buildPeerConnection));
    vi.stubGlobal(
      'AudioContext',
      vi.fn(() => ({
        state: 'running',
        resume: () => Promise.resolve(),
        close: () => Promise.resolve(),
        createMediaStreamDestination: () => ({ stream: 'mixed-stream' }),
        createMediaStreamSource: () => ({ connect: () => {} }),
      }))
    );
    vi.stubGlobal('navigator', {
      mediaDevices: {
        getUserMedia: () => Promise.resolve(buildMediaStream([audioTrack])),
      },
    });
    // jsdom's HTMLMediaElement has no play() implementation.
    window.HTMLMediaElement.prototype.play = vi.fn().mockResolvedValue();
    WhatsappCallsAPI.accept.mockResolvedValue({});
    WhatsappCallsAPI.terminate.mockResolvedValue({});
    WhatsappCallsAPI.uploadRecording.mockResolvedValue({});
  });

  afterEach(() => {
    cleanupWhatsappSession();
    vi.unstubAllGlobals();
    vi.clearAllMocks();
  });

  const acceptCall = recordingEnabled =>
    useWhatsappCallSession().acceptIncomingCall({
      callId: CALL_ID,
      sdpOffer: SDP_OFFER,
      iceServers: [],
      recordingEnabled,
    });

  it('records the call and uploads it when the inbox has recording on', async () => {
    const session = useWhatsappCallSession();
    await acceptCall(true);

    expect(recorders).toHaveLength(1);

    await session.endActiveCall();

    expect(WhatsappCallsAPI.uploadRecording).toHaveBeenCalledWith(
      CALL_ID,
      expect.any(Blob)
    );
  });

  it('never starts a recorder or uploads audio when recording is off', async () => {
    const session = useWhatsappCallSession();
    await acceptCall(false);

    expect(recorders).toHaveLength(0);

    await session.endActiveCall();

    expect(WhatsappCallsAPI.uploadRecording).not.toHaveBeenCalled();
  });

  it('records when the ring payload predates the setting and carries no flag', async () => {
    await acceptCall(undefined);

    expect(recorders).toHaveLength(1);
  });

  it('reads the setting from the call payload when the ring broadcast was missed', async () => {
    WhatsappCallsAPI.show.mockResolvedValue({
      sdp_offer: SDP_OFFER,
      ice_servers: [],
      recording_enabled: false,
    });

    await useWhatsappCallSession().acceptIncomingCall({ callId: CALL_ID });

    expect(WhatsappCallsAPI.show).toHaveBeenCalledWith(CALL_ID);
    expect(recorders).toHaveLength(0);
  });
});
