import { readonly, ref } from 'vue';
import PathorsCallsAPI from 'dashboard/api/pathorsCalls';

/**
 * Human takeover of a Pathors voice call.
 *
 * The Pathors backend owns the LiveKit room the AI agent is already speaking
 * in; POST .../pathors/calls/:id/join asks it to yield and hands back a
 * participant token. Everything below is just: redeem the token, publish the
 * mic, play whatever comes back.
 *
 * State is module-level on purpose. Every voice_call bubble in the thread
 * instantiates this composable, and a browser can only be in one call at a
 * time — a per-instance ref would let two bubbles (or two threads) join in
 * parallel and fight over the same microphone.
 */

export const PATHORS_JOIN_ERROR = {
  ALREADY_CLAIMED: 'already_claimed',
  CALL_ENDED: 'call_ended',
  MEDIA_DENIED: 'media_denied',
  UNAVAILABLE: 'unavailable',
};

const AUDIO_ELEMENT_CLASS = 'pathors-call-audio';
const DURATION_TICK_MS = 1000;

const isJoining = ref(false);
const isJoined = ref(false);
const error = ref(null);
const durationSeconds = ref(0);
// Which call this tab is in, so a second bubble can tell "someone else's call
// is live" from "my call is live".
const activeCallId = ref(null);

let room = null;
let durationTimer = null;
let attachedElements = [];

const stopDurationTimer = () => {
  if (!durationTimer) return;
  clearInterval(durationTimer);
  durationTimer = null;
};

const startDurationTimer = () => {
  stopDurationTimer();
  durationSeconds.value = 0;
  const startedAt = Date.now();
  durationTimer = setInterval(() => {
    durationSeconds.value = Math.floor((Date.now() - startedAt) / 1000);
  }, DURATION_TICK_MS);
};

const detachAllAudio = () => {
  attachedElements.forEach(el => {
    el.srcObject = null;
    el.remove();
  });
  attachedElements = [];
};

const attachAudioTrack = track => {
  if (track?.kind !== 'audio') return;
  const el = track.attach();
  el.autoplay = true;
  el.classList.add(AUDIO_ELEMENT_CLASS);
  el.style.display = 'none';
  document.body.appendChild(el);
  attachedElements.push(el);
  // Autoplay policies can still refuse; the agent already gesture-clicked
  // "join", so this is a belt-and-braces retry rather than the happy path.
  const played = el.play?.();
  if (played?.catch) played.catch(() => {});
};

const detachAudioTrack = track => {
  if (track?.kind !== 'audio') return;
  const elements = track.detach();
  elements.forEach(el => {
    attachedElements = attachedElements.filter(item => item !== el);
    el.remove();
  });
};

const resetSession = () => {
  stopDurationTimer();
  detachAllAudio();
  room = null;
  isJoined.value = false;
  isJoining.value = false;
  activeCallId.value = null;
  durationSeconds.value = 0;
};

// Maps the relay's HTTP answer onto a code the bubble can phrase. 409 is the
// race we expect most often (another dashboard answered first); 404/410 mean
// the call is already over.
const errorCodeFor = requestError => {
  const status = requestError?.response?.status;
  if (status === 409) return PATHORS_JOIN_ERROR.ALREADY_CLAIMED;
  if (status === 404 || status === 410) return PATHORS_JOIN_ERROR.CALL_ENDED;
  return PATHORS_JOIN_ERROR.UNAVAILABLE;
};

const connectToRoom = async credentials => {
  const { Room, RoomEvent } = await import('livekit-client');

  room = new Room();
  room.on(RoomEvent.TrackSubscribed, track => attachAudioTrack(track));
  room.on(RoomEvent.TrackUnsubscribed, track => detachAudioTrack(track));
  // A remote disconnect (call ended, token expired, agent kicked) has to land
  // back on the same teardown as an explicit leave, or the bubble stays stuck
  // showing "leave".
  room.on(RoomEvent.Disconnected, () => resetSession());

  await room.connect(credentials.serverUrl, credentials.token);
  await room.localParticipant.setMicrophoneEnabled(true);
};

export function usePathorsCallSession() {
  /**
   * @param {{ accountId?: number|string, callId: number|string }} params
   * @returns {Promise<boolean>} true when the agent is in the room
   */
  const join = async ({ accountId, callId } = {}) => {
    if (!callId) return false;
    // Guard both directions: a second click on this bubble, and a click on a
    // different bubble while a call is already live.
    if (isJoining.value || isJoined.value) return false;

    isJoining.value = true;
    error.value = null;

    let credentials = null;
    try {
      credentials = await PathorsCallsAPI.join(callId, accountId);
    } catch (requestError) {
      error.value = errorCodeFor(requestError);
      isJoining.value = false;
      return false;
    }

    if (!credentials?.token || !credentials?.serverUrl) {
      error.value = PATHORS_JOIN_ERROR.UNAVAILABLE;
      isJoining.value = false;
      return false;
    }

    try {
      await connectToRoom(credentials);
    } catch (connectError) {
      // getUserMedia rejections are the one failure the agent can fix
      // themselves (grant the mic), so they get their own message.
      const isMediaError = /NotAllowed|Permission|NotFound/i.test(
        connectError?.name || connectError?.message || ''
      );
      try {
        await room?.disconnect();
      } catch (_) {
        /* noop — nothing to tear down */
      }
      resetSession();
      error.value = isMediaError
        ? PATHORS_JOIN_ERROR.MEDIA_DENIED
        : PATHORS_JOIN_ERROR.UNAVAILABLE;
      return false;
    }

    isJoining.value = false;
    isJoined.value = true;
    activeCallId.value = callId;
    startDurationTimer();
    return true;
  };

  const leave = async () => {
    const activeRoom = room;
    // Reset first so the UI flips back immediately even if disconnect() hangs;
    // the Disconnected handler is a no-op once state is already clear.
    resetSession();
    if (!activeRoom) return;
    try {
      await activeRoom.disconnect();
    } catch (_) {
      /* noop — the room is gone either way */
    }
  };

  const isActiveCall = callId =>
    activeCallId.value != null && String(activeCallId.value) === String(callId);

  return {
    join,
    // Alias kept for call sites that read better as a verb+noun.
    joinCall: join,
    leave,
    isJoining: readonly(isJoining),
    isJoined: readonly(isJoined),
    error: readonly(error),
    durationSeconds: readonly(durationSeconds),
    activeCallId: readonly(activeCallId),
    isActiveCall,
  };
}

// Test seam: the module-level singleton would otherwise leak between specs.
export const resetPathorsCallSession = () => {
  room = null;
  resetSession();
  error.value = null;
};
