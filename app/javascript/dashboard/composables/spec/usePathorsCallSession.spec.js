import {
  usePathorsCallSession,
  resetPathorsCallSession,
  PATHORS_JOIN_ERROR,
} from '../usePathorsCallSession';
import PathorsCallsAPI from 'dashboard/api/pathorsCalls';

vi.mock('dashboard/api/pathorsCalls', () => ({
  default: { join: vi.fn() },
}));

const ROOM_EVENT = {
  TrackSubscribed: 'trackSubscribed',
  TrackUnsubscribed: 'trackUnsubscribed',
  Disconnected: 'disconnected',
};

// Hoisted so the vi.mock factory below (which runs before the module body) can
// reach the same room registry the tests assert on.
const { FakeRoom, rooms, micState } = vi.hoisted(() => {
  const registry = [];
  // Set by a test to make the next room's microphone request reject.
  const state = { nextError: null };

  class Room {
    constructor() {
      this.handlers = {};
      this.connect = vi.fn().mockResolvedValue(undefined);
      this.disconnect = vi.fn().mockResolvedValue(undefined);
      const micError = state.nextError;
      state.nextError = null;
      this.localParticipant = {
        setMicrophoneEnabled: micError
          ? vi.fn().mockRejectedValue(micError)
          : vi.fn().mockResolvedValue(undefined),
      };
      registry.push(this);
    }

    on(event, handler) {
      this.handlers[event] = handler;
      return this;
    }

    emit(event, ...args) {
      this.handlers[event]?.(...args);
    }
  }

  return { FakeRoom: Room, rooms: registry, micState: state };
});

vi.mock('livekit-client', () => ({
  Room: FakeRoom,
  RoomEvent: {
    TrackSubscribed: 'trackSubscribed',
    TrackUnsubscribed: 'trackUnsubscribed',
    Disconnected: 'disconnected',
  },
}));

const credentials = {
  token: 'lk-token',
  serverUrl: 'wss://livekit.example',
  roomName: 'room-1',
  participantIdentity: 'chatwoot-human-7',
  yieldDelivered: true,
};

const rejectWith = status => {
  const error = new Error(`Request failed with status ${status}`);
  error.response = { status };
  return Promise.reject(error);
};

describe('usePathorsCallSession', () => {
  beforeEach(() => {
    rooms.length = 0;
    micState.nextError = null;
    vi.clearAllMocks();
    resetPathorsCallSession();
  });

  afterEach(() => {
    resetPathorsCallSession();
  });

  it('joins the room and publishes the microphone', async () => {
    PathorsCallsAPI.join.mockResolvedValue(credentials);
    const { join, isJoined, isJoining, isActiveCall } = usePathorsCallSession();

    const joined = await join({ accountId: 3, callId: 42 });

    expect(joined).toBe(true);
    expect(PathorsCallsAPI.join).toHaveBeenCalledWith(42, 3);
    expect(rooms[0].connect).toHaveBeenCalledWith(
      'wss://livekit.example',
      'lk-token'
    );
    expect(rooms[0].localParticipant.setMicrophoneEnabled).toHaveBeenCalledWith(
      true
    );
    expect(isJoined.value).toBe(true);
    expect(isJoining.value).toBe(false);
    expect(isActiveCall(42)).toBe(true);
  });

  it('attaches subscribed audio tracks to a hidden autoplay element', async () => {
    PathorsCallsAPI.join.mockResolvedValue(credentials);
    const { join, leave } = usePathorsCallSession();
    await join({ accountId: 3, callId: 42 });

    const element = document.createElement('audio');
    element.play = vi.fn().mockResolvedValue(undefined);
    const track = {
      kind: 'audio',
      attach: () => element,
      detach: () => [element],
    };

    rooms[0].emit(ROOM_EVENT.TrackSubscribed, track);

    expect(element.autoplay).toBe(true);
    expect(element.style.display).toBe('none');
    expect(document.body.contains(element)).toBe(true);

    await leave();

    expect(document.body.contains(element)).toBe(false);
  });

  it('reports a 409 as already claimed and stays out of the room', async () => {
    PathorsCallsAPI.join.mockImplementation(() => rejectWith(409));
    const { join, error, isJoined } = usePathorsCallSession();

    const joined = await join({ accountId: 3, callId: 42 });

    expect(joined).toBe(false);
    expect(error.value).toBe(PATHORS_JOIN_ERROR.ALREADY_CLAIMED);
    expect(isJoined.value).toBe(false);
    expect(rooms).toHaveLength(0);
  });

  it('reports a 404 and a 410 as an ended call', async () => {
    const { join, error } = usePathorsCallSession();

    PathorsCallsAPI.join.mockImplementation(() => rejectWith(404));
    await join({ accountId: 3, callId: 42 });
    expect(error.value).toBe(PATHORS_JOIN_ERROR.CALL_ENDED);

    resetPathorsCallSession();
    PathorsCallsAPI.join.mockImplementation(() => rejectWith(410));
    await join({ accountId: 3, callId: 42 });
    expect(error.value).toBe(PATHORS_JOIN_ERROR.CALL_ENDED);
  });

  it('refuses a second join while a call is already live', async () => {
    PathorsCallsAPI.join.mockResolvedValue(credentials);
    const { join } = usePathorsCallSession();
    await join({ accountId: 3, callId: 42 });

    // A different bubble, sharing the module-level singleton.
    const second = usePathorsCallSession();
    const joined = await second.join({ accountId: 3, callId: 99 });

    expect(joined).toBe(false);
    expect(PathorsCallsAPI.join).toHaveBeenCalledTimes(1);
    expect(rooms).toHaveLength(1);
  });

  it('disconnects and clears the session on leave', async () => {
    PathorsCallsAPI.join.mockResolvedValue(credentials);
    const { join, leave, isJoined, durationSeconds, isActiveCall } =
      usePathorsCallSession();
    await join({ accountId: 3, callId: 42 });

    await leave();

    expect(rooms[0].disconnect).toHaveBeenCalled();
    expect(isJoined.value).toBe(false);
    expect(durationSeconds.value).toBe(0);
    expect(isActiveCall(42)).toBe(false);
  });

  it('clears the session when the room drops the connection', async () => {
    PathorsCallsAPI.join.mockResolvedValue(credentials);
    const { join, isJoined } = usePathorsCallSession();
    await join({ accountId: 3, callId: 42 });

    rooms[0].emit(ROOM_EVENT.Disconnected);

    expect(isJoined.value).toBe(false);
  });

  it('surfaces a missing token as an unavailable backend', async () => {
    PathorsCallsAPI.join.mockResolvedValue({ serverUrl: 'wss://x' });
    const { join, error, isJoined } = usePathorsCallSession();

    const joined = await join({ accountId: 3, callId: 42 });

    expect(joined).toBe(false);
    expect(error.value).toBe(PATHORS_JOIN_ERROR.UNAVAILABLE);
    expect(isJoined.value).toBe(false);
  });

  it('reports a denied microphone distinctly', async () => {
    PathorsCallsAPI.join.mockResolvedValue(credentials);
    micState.nextError = Object.assign(new Error('denied'), {
      name: 'NotAllowedError',
    });
    const { join, error, isJoined } = usePathorsCallSession();

    const joined = await join({ accountId: 3, callId: 42 });

    expect(joined).toBe(false);
    expect(error.value).toBe(PATHORS_JOIN_ERROR.MEDIA_DENIED);
    expect(isJoined.value).toBe(false);
    expect(rooms[0].disconnect).toHaveBeenCalled();
  });
});
