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

  // Register cleanup callback so store can trigger WebRTC teardown on external events
  callsStore.registerCleanupCallback(() => {
    cleanupWebRTC();
    durationTimer.stop();
    callDuration.value = 0;
  });

  /**
   * Waits for ICE candidate gathering to complete so the SDP contains all candidates.
   * Meta's REST API doesn't support trickle ICE — the full SDP must be sent at once.
   */
  const waitForIceGatheringComplete = pc =>
    new Promise((resolve, reject) => {
      if (pc.iceGatheringState === 'complete') {
        resolve();
        return;
      }

      const timeout = setTimeout(() => {
        // If gathering hasn't finished in 10s, send what we have
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

      // Also reject if connection fails during gathering
      pc.oniceconnectionstatechange = () => {
        if (pc.iceConnectionState === 'failed') {
          clearTimeout(timeout);
          reject(new Error('ICE connection failed'));
        }
      };
    });

  /**
   * Accepts an incoming WhatsApp call:
   * 1. Requests mic access
   * 2. Creates RTCPeerConnection with ICE servers from the call payload
   * 3. Sets remote description (the SDP offer from Meta)
   * 4. Creates an SDP answer
   * 5. Waits for ICE gathering to complete (Meta needs full SDP, no trickle ICE)
   * 6. Posts the complete SDP answer to Chatwoot backend → Meta API
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

      // 5. Handle remote audio stream → play via <audio> element
      peerConnection.ontrack = event => {
        const [stream] = event.streams;
        if (!stream) return;

        if (remoteAudio.value) {
          remoteAudio.value.srcObject = stream;
          remoteAudio.value.play().catch(e => {
            // eslint-disable-next-line no-console
            console.warn('[WhatsApp Call] Audio autoplay blocked:', e);
          });
        } else {
          const audio = document.createElement('audio');
          audio.srcObject = stream;
          audio.autoplay = true;
          document.body.appendChild(audio);
          remoteAudio.value = audio;
        }
      };

      // 6. Monitor ICE connection state for debugging
      peerConnection.oniceconnectionstatechange = () => {
        // eslint-disable-next-line no-console
        console.log(
          '[WhatsApp Call] ICE state:',
          peerConnection?.iceConnectionState
        );
      };

      // 7. Set remote description from Meta's SDP offer
      await peerConnection.setRemoteDescription({
        type: 'offer',
        sdp: call.sdpOffer,
      });

      // 8. Create SDP answer
      const answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      // 9. Wait for ICE gathering to complete so SDP has all candidates
      await waitForIceGatheringComplete(peerConnection);

      // 10. Post the COMPLETE SDP answer (with all ICE candidates) to backend
      const completeSdp = peerConnection.localDescription.sdp;
      await WhatsappCallsAPI.accept(call.id, completeSdp);

      // 11. Mark as active in store
      callsStore.removeIncomingCall(call.callId);
      callsStore.setActiveCall({
        ...call,
      });

      durationTimer.start();
    } catch (err) {
      callError.value =
        err.name === 'NotAllowedError'
          ? 'Microphone access denied. Please allow mic access and try again.'
          : 'Failed to accept call. Please try again.';
      // eslint-disable-next-line no-console
      console.error('[WhatsApp Call] acceptCall error:', err);
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
