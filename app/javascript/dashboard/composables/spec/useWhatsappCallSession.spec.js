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

const SDP = 'v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\n';
const CALL_ID = 42;
const track = { kind: 'audio', stop: vi.fn() };

const stream = (tracks = []) => ({
  addTrack: t => tracks.push(t),
  getTracks: () => tracks,
  getAudioTracks: () => tracks.filter(t => t.kind === 'audio'),
});

describe('useWhatsappCallSession recording gate', () => {
  let recorders;

  beforeEach(() => {
    recorders = [];
    const recorder = vi.fn(() => {
      const r = {
        state: 'inactive',
        ondataavailable: null,
        addEventListener: (e, h) => {
          if (e === 'stop') r.onstop = h;
        },
        // One chunk on start, so the upload path has something to send.
        start: () => {
          r.state = 'recording';
          r.ondataavailable?.({
            data: new Blob(['x'], { type: 'audio/webm' }),
          });
        },
        stop: () => {
          r.state = 'inactive';
          r.onstop?.();
        },
      };
      recorders.push(r);
      return r;
    });
    recorder.isTypeSupported = () => true;

    vi.stubGlobal('MediaRecorder', recorder);
    vi.stubGlobal(
      'MediaStream',
      vi.fn(() => stream([]))
    );
    vi.stubGlobal(
      'RTCPeerConnection',
      vi.fn(() => ({
        iceGatheringState: 'complete',
        localDescription: { sdp: 'answer' },
        ontrack: null,
        addTrack: () => {},
        addEventListener: () => {},
        createAnswer: () => Promise.resolve({ type: 'answer', sdp: 'answer' }),
        setLocalDescription: () => Promise.resolve(),
        // Meta's offer landing is what fires ontrack in the real browser.
        setRemoteDescription() {
          this.ontrack?.({ streams: [stream([track])], track });
          return Promise.resolve();
        },
        close: () => {},
      }))
    );
    vi.stubGlobal(
      'AudioContext',
      vi.fn(() => ({
        resume: () => Promise.resolve(),
        close: () => Promise.resolve(),
        createMediaStreamDestination: () => ({ stream: 'mixed' }),
        createMediaStreamSource: () => ({ connect: () => {} }),
      }))
    );
    vi.stubGlobal('navigator', {
      mediaDevices: { getUserMedia: () => Promise.resolve(stream([track])) },
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

  const accept = recordingEnabled =>
    useWhatsappCallSession().acceptIncomingCall({
      callId: CALL_ID,
      sdpOffer: SDP,
      iceServers: [],
      recordingEnabled,
    });

  it('records and uploads when recording is on', async () => {
    const session = useWhatsappCallSession();
    await accept(true);
    expect(recorders).toHaveLength(1);

    await session.endActiveCall();
    expect(WhatsappCallsAPI.uploadRecording).toHaveBeenCalledWith(
      CALL_ID,
      expect.any(Blob)
    );
  });

  it('captures and uploads nothing when recording is off', async () => {
    const session = useWhatsappCallSession();
    await accept(false);
    expect(recorders).toHaveLength(0);

    await session.endActiveCall();
    expect(WhatsappCallsAPI.uploadRecording).not.toHaveBeenCalled();
  });

  it('falls back to the call payload when the ring broadcast was missed', async () => {
    WhatsappCallsAPI.show.mockResolvedValue({
      sdp_offer: SDP,
      ice_servers: [],
      recording_enabled: false,
    });

    await useWhatsappCallSession().acceptIncomingCall({ callId: CALL_ID });

    expect(recorders).toHaveLength(0);
  });
});
