import { ref, computed, watch, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  useWhatsappCallsStore,
  getOutboundCallState,
} from 'dashboard/stores/whatsappCalls';
import WhatsappCallsAPI from 'dashboard/api/whatsappCalls';
import Auth from 'dashboard/api/auth';
import Timer from 'dashboard/helper/Timer';

// ── Module-level WebRTC state for inbound calls accepted from anywhere ──
// Kept at module scope so both the composable and acceptWhatsappCallById share it.
let inboundPc = null;
let inboundStream = null;
let inboundAudio = null;

// ── Module-level recording state ──
let mediaRecorder = null;
let recordedChunks = [];
let recordingCallId = null;

function cleanupInboundWebRTC() {
  if (inboundStream) {
    inboundStream.getTracks().forEach(track => track.stop());
    inboundStream = null;
  }
  if (inboundPc) {
    inboundPc.close();
    inboundPc = null;
  }
  if (inboundAudio) {
    inboundAudio.srcObject = null;
    if (inboundAudio.parentNode) {
      inboundAudio.parentNode.removeChild(inboundAudio);
    }
    inboundAudio = null;
  }
}

/**
 * Start recording both local and remote audio tracks via MediaRecorder.
 * Mixes them into a single stream using AudioContext.
 */
export function startCallRecording(pc, localStream, callId) {
  try {
    const ctx = new AudioContext();
    const dest = ctx.createMediaStreamDestination();

    // Add local mic track
    if (localStream) {
      const localSource = ctx.createMediaStreamSource(localStream);
      localSource.connect(dest);
    }

    // Add remote tracks from peer connection
    pc.getReceivers().forEach(receiver => {
      if (receiver.track && receiver.track.kind === 'audio') {
        const remoteStream = new MediaStream([receiver.track]);
        const remoteSource = ctx.createMediaStreamSource(remoteStream);
        remoteSource.connect(dest);
      }
    });

    recordedChunks = [];
    recordingCallId = callId;
    const recorder = new MediaRecorder(dest.stream, {
      mimeType: 'audio/webm;codecs=opus',
    });

    recorder.ondataavailable = e => {
      if (e.data.size > 0) recordedChunks.push(e.data);
    };

    mediaRecorder = recorder;
    recorder.start(1000);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[WhatsApp Call] Failed to start recording:', err);
  }
}

/**
 * Stop recording and upload the audio blob to the backend.
 */
function stopAndUploadRecording(callId) {
  if (!mediaRecorder || mediaRecorder.state === 'inactive') return;

  const id = callId || recordingCallId;

  mediaRecorder.onstop = () => {
    if (recordedChunks.length === 0 || !id) return;

    const blob = new Blob(recordedChunks, { type: 'audio/webm' });
    recordedChunks = [];
    recordingCallId = null;

    WhatsappCallsAPI.uploadRecording(id, blob).catch(err => {
      // eslint-disable-next-line no-console
      console.error('[WhatsApp Call] Failed to upload recording:', err);
    });
  };

  mediaRecorder.stop();
  mediaRecorder = null;
}

function waitForIceGatheringComplete(pc) {
  return new Promise((resolve, reject) => {
    if (pc.iceGatheringState === 'complete') {
      resolve();
      return;
    }
    const timeout = setTimeout(() => {
      // eslint-disable-next-line no-console
      console.warn(
        '[WhatsApp Call] ICE gathering timed out, sending partial SDP'
      );
      resolve();
    }, 10000);

    pc.onicegatheringstatechange = () => {
      if (pc.iceGatheringState === 'complete') {
        clearTimeout(timeout);
        resolve();
      }
    };
    pc.oniceconnectionstatechange = () => {
      if (pc.iceConnectionState === 'failed') {
        clearTimeout(timeout);
        reject(new Error('ICE connection failed'));
      }
    };
  });
}

/**
 * Core accept logic: creates WebRTC session and posts SDP to backend.
 * Can be called from anywhere — composable, widget, or bubble.
 * Returns { success: true } or { success: false, error }.
 */
async function doAcceptCall(call) {
  cleanupInboundWebRTC();

  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  inboundStream = stream;

  const iceServers = call.iceServers?.length
    ? call.iceServers
    : [{ urls: 'stun:stun.l.google.com:19302' }];

  const pc = new RTCPeerConnection({ iceServers });
  inboundPc = pc;

  stream.getTracks().forEach(track => pc.addTrack(track, stream));

  pc.ontrack = event => {
    const [remoteStream] = event.streams;
    if (!remoteStream) return;
    if (!inboundAudio) {
      const audio = document.createElement('audio');
      audio.autoplay = true;
      document.body.appendChild(audio);
      inboundAudio = audio;
    }
    inboundAudio.srcObject = remoteStream;
    inboundAudio.play().catch(() => {});

    // Start recording once remote audio is available
    startCallRecording(pc, stream, call.id);
  };

  await pc.setRemoteDescription({ type: 'offer', sdp: call.sdpOffer });
  const answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);
  await waitForIceGatheringComplete(pc);

  const completeSdp = pc.localDescription.sdp;
  await WhatsappCallsAPI.accept(call.id, completeSdp);

  return { success: true };
}

/**
 * Standalone function callable from VoiceCall bubble.
 * Fetches call data if needed, runs WebRTC accept, updates store.
 */
export async function acceptWhatsappCallById(waCallId) {
  const callsStore = useWhatsappCallsStore();

  if (callsStore.hasActiveCall) {
    return { success: false, error: 'active_call_exists' };
  }

  // 1. Check if the call is already in the incoming store
  let call = callsStore.incomingCalls.find(
    c => c.id === waCallId || c.waCallId === waCallId
  );

  // 2. Not in store (page was refreshed) → fetch from API
  if (!call) {
    const { data } = await WhatsappCallsAPI.show(waCallId);
    if (data.status !== 'ringing') {
      return { success: false, error: 'not_ringing' };
    }
    call = {
      id: data.id,
      callId: data.call_id,
      waCallId: data.id,
      direction: data.direction,
      inboxId: data.inbox_id,
      conversationId: data.conversation_id,
      sdpOffer: data.sdp_offer,
      iceServers: data.ice_servers,
      caller: data.caller,
    };
    callsStore.addIncomingCall(call);
  }

  // 3. Run the WebRTC accept
  await doAcceptCall(call);

  // 4. Move from incoming to active
  callsStore.removeIncomingCall(call.callId);
  callsStore.setActiveCall({ ...call });

  return { success: true, call };
}

/**
 * Fire-and-forget terminate request using fetch + keepalive.
 * Works reliably inside beforeunload / pagehide where axios won't complete.
 */
function terminateCallOnUnload(callId) {
  const authData = Auth.hasAuthCookie() ? Auth.getAuthData() : {};
  const accountId =
    window.location.pathname.includes('/app/accounts') &&
    window.location.pathname.split('/')[3];
  if (!accountId) return;

  const url = `/api/v1/accounts/${accountId}/whatsapp_calls/${callId}/terminate`;
  fetch(url, {
    method: 'POST',
    keepalive: true,
    headers: {
      'Content-Type': 'application/json',
      'access-token': authData['access-token'] || '',
      'token-type': authData['token-type'] || '',
      client: authData.client || '',
      expiry: authData.expiry || '',
      uid: authData.uid || '',
    },
  }).catch(() => {});
}

// ── Composable (used by WhatsappCallWidget for floating UI + timer) ──
export function useWhatsappCallSession() {
  const { t } = useI18n();
  const callsStore = useWhatsappCallsStore();

  const isAccepting = ref(false);
  const isMuted = ref(false);
  const callError = ref(null);
  const callDuration = ref(0);

  const durationTimer = new Timer(elapsed => {
    callDuration.value = elapsed;
  });

  const activeCall = computed(() => callsStore.activeCall);
  const incomingCalls = computed(() => callsStore.incomingCalls);
  const hasActiveCall = computed(() => callsStore.hasActiveCall);
  const hasIncomingCall = computed(() => callsStore.hasIncomingCall);
  const firstIncomingCall = computed(() => callsStore.firstIncomingCall);

  const isOutboundRinging = computed(
    () =>
      activeCall.value?.direction === 'outbound' &&
      activeCall.value?.status === 'ringing'
  );

  const formattedCallDuration = computed(() => {
    const minutes = Math.floor(callDuration.value / 60);
    const seconds = callDuration.value % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  });

  // Register cleanup so external call-end events can teardown WebRTC
  callsStore.registerCleanupCallback(() => {
    stopAndUploadRecording();
    cleanupInboundWebRTC();
    durationTimer.stop();
    callDuration.value = 0;
  });

  // Terminate active call on page close / reload
  const handleBeforeUnload = () => {
    const call = callsStore.activeCall;
    if (call?.id) {
      terminateCallOnUnload(call.id);
      cleanupInboundWebRTC();
    }
  };
  window.addEventListener('beforeunload', handleBeforeUnload);

  // Start timer when outbound call becomes connected
  watch(activeCall, call => {
    if (
      call?.direction === 'outbound' &&
      call?.status === 'connected' &&
      !durationTimer.intervalId
    ) {
      durationTimer.start();
    }
  });

  /**
   * Accept an incoming call — used by the floating widget buttons.
   * Uses the same doAcceptCall core + starts the timer.
   */
  const acceptCall = async call => {
    if (isAccepting.value) return;
    isAccepting.value = true;
    callError.value = null;

    try {
      await doAcceptCall(call);
      callsStore.removeIncomingCall(call.callId);
      callsStore.setActiveCall({ ...call });
      durationTimer.start();
    } catch (err) {
      callError.value =
        err.name === 'NotAllowedError'
          ? t('WHATSAPP_CALL.MIC_DENIED')
          : t('WHATSAPP_CALL.CALL_FAILED');
      // eslint-disable-next-line no-console
      console.error('[WhatsApp Call] acceptCall error:', err);
      cleanupInboundWebRTC();
    } finally {
      isAccepting.value = false;
    }
  };

  const rejectCall = async call => {
    try {
      await WhatsappCallsAPI.reject(call.id);
    } catch {
      // Best effort
    } finally {
      callsStore.removeIncomingCall(call.callId);
    }
  };

  const endActiveCall = async () => {
    const call = activeCall.value;
    if (!call) return;

    stopAndUploadRecording(call.id);

    try {
      await WhatsappCallsAPI.terminate(call.id);
    } catch {
      // Best effort
    } finally {
      cleanupInboundWebRTC();
      callsStore.handleCallEnded(call.callId);
      callsStore.clearActiveCall();
      durationTimer.stop();
      callDuration.value = 0;
    }
  };

  const toggleMute = () => {
    const stream = inboundStream || getOutboundCallState().stream;
    if (!stream) return;
    const audioTrack = stream.getAudioTracks()[0];
    if (!audioTrack) return;
    audioTrack.enabled = !audioTrack.enabled;
    isMuted.value = !audioTrack.enabled;
  };

  const dismissIncomingCall = call => {
    callsStore.removeIncomingCall(call.callId);
  };

  onUnmounted(() => {
    window.removeEventListener('beforeunload', handleBeforeUnload);
    durationTimer.stop();
  });

  return {
    activeCall,
    incomingCalls,
    hasActiveCall,
    hasIncomingCall,
    firstIncomingCall,
    isAccepting,
    isMuted,
    isOutboundRinging,
    callError,
    formattedCallDuration,
    acceptCall,
    rejectCall,
    endActiveCall,
    toggleMute,
    dismissIncomingCall,
  };
}
