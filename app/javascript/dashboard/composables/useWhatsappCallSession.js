import { ref, computed, onUnmounted } from 'vue';
import { useWhatsappCallsStore } from 'dashboard/stores/whatsappCalls';
import WhatsappCallsAPI from 'dashboard/api/whatsappCalls';
import Timer from 'dashboard/helper/Timer';

export function useWhatsappCallSession() {
  const callsStore = useWhatsappCallsStore();

  // WebRTC internals
  let peerConnection = null;
  let localStream = null;
  const remoteAudio = ref(null);

  // UI state
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

  const formattedCallDuration = computed(() => {
    const minutes = Math.floor(callDuration.value / 60);
    const seconds = callDuration.value % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  });

  const cleanupWebRTC = () => {
    if (localStream) {
      localStream.getTracks().forEach(t => t.stop());
      localStream = null;
    }
    if (peerConnection) {
      peerConnection.close();
      peerConnection = null;
    }
    if (remoteAudio.value) {
      remoteAudio.value.srcObject = null;
      // Remove dynamically created audio element from DOM
      if (remoteAudio.value.parentNode) {
        remoteAudio.value.parentNode.removeChild(remoteAudio.value);
      }
      remoteAudio.value = null;
    }
  };

  /**
   * Accepts an incoming WhatsApp call:
   * 1. Requests mic access
   * 2. Creates RTCPeerConnection with ICE servers from the call payload
   * 3. Sets remote description (the SDP offer from Meta)
   * 4. Creates an SDP answer
   * 5. Posts the SDP answer to Chatwoot backend → Meta API
   */
  const acceptCall = async call => {
    if (isAccepting.value) return;
    isAccepting.value = true;
    callError.value = null;

    try {
      // 1. Get microphone access
      localStream = await navigator.mediaDevices.getUserMedia({ audio: true });

      // 2. Build ICE config
      const iceServers = call.iceServers?.length
        ? call.iceServers
        : [{ urls: 'stun:stun.l.google.com:19302' }];

      // 3. Create RTCPeerConnection
      peerConnection = new RTCPeerConnection({ iceServers });

      // 4. Add local audio tracks
      localStream.getTracks().forEach(track => {
        peerConnection.addTrack(track, localStream);
      });

      // 5. Handle remote audio stream → play via hidden <audio> element
      peerConnection.ontrack = event => {
        const [stream] = event.streams;
        if (remoteAudio.value) {
          remoteAudio.value.srcObject = stream;
          remoteAudio.value.play().catch(() => {});
        } else {
          // Fallback: create audio element dynamically
          const audio = document.createElement('audio');
          audio.srcObject = stream;
          audio.autoplay = true;
          document.body.appendChild(audio);
          remoteAudio.value = audio;
        }
      };

      // 6. Set remote description from Meta's SDP offer
      await peerConnection.setRemoteDescription({
        type: 'offer',
        sdp: call.sdpOffer,
      });

      // 7. Create SDP answer
      const answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      // 8. Post the SDP answer to Chatwoot backend
      await WhatsappCallsAPI.accept(call.id, answer.sdp);

      // 9. Mark as active in store
      callsStore.removeIncomingCall(call.callId);
      callsStore.setActiveCall({
        ...call,
        peerConnection,
      });

      durationTimer.start();
    } catch (err) {
      callError.value =
        err.name === 'NotAllowedError'
          ? 'Microphone access denied. Please allow mic access and try again.'
          : 'Failed to accept call. Please try again.';
      cleanupWebRTC();
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

    try {
      await WhatsappCallsAPI.terminate(call.id);
    } catch {
      // Best effort — always cleanup locally
    } finally {
      cleanupWebRTC();
      callsStore.clearActiveCall();
      durationTimer.stop();
      callDuration.value = 0;
    }
  };

  const toggleMute = () => {
    if (!localStream) return;
    const audioTrack = localStream.getAudioTracks()[0];
    if (!audioTrack) return;
    audioTrack.enabled = !audioTrack.enabled;
    isMuted.value = !audioTrack.enabled;
  };

  const dismissIncomingCall = call => {
    callsStore.removeIncomingCall(call.callId);
  };

  onUnmounted(() => {
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
    callError,
    formattedCallDuration,
    acceptCall,
    rejectCall,
    endActiveCall,
    toggleMute,
    dismissIncomingCall,
  };
}
