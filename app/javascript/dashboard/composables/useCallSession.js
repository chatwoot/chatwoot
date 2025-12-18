import { computed, ref, watch, onUnmounted, onMounted } from 'vue';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import { useCallsStore } from 'dashboard/stores/calls';
import Timer from 'dashboard/helper/Timer';

const CALL_STATES = {
  IDLE: 'idle',
  INCOMING: 'incoming',
  OUTGOING: 'outgoing',
  JOINED: 'joined',
};

export function useCallSession() {
  const callsStore = useCallsStore();
  const isJoining = ref(false);
  const callDuration = ref(0);
  const durationTimer = new Timer(elapsed => {
    callDuration.value = elapsed;
  });

  const activeCall = computed(() => callsStore.getActiveCall);
  const incomingCall = computed(() => callsStore.getIncomingCall);
  const hasActiveCall = computed(() => callsStore.hasActiveCall);
  const hasIncomingCall = computed(() => callsStore.hasIncomingCall);

  const isJoined = computed(() => activeCall.value?.isJoined === true);

  const isOutbound = computed(() => {
    const call = incomingCall.value || activeCall.value;
    return call?.callDirection === 'outbound';
  });

  const callState = computed(() => {
    if (isJoined.value) return CALL_STATES.JOINED;
    if (hasIncomingCall.value && isOutbound.value) {
      return CALL_STATES.OUTGOING;
    }
    if (hasIncomingCall.value && !hasActiveCall.value) {
      return CALL_STATES.INCOMING;
    }
    if (hasActiveCall.value) return CALL_STATES.OUTGOING;
    return CALL_STATES.IDLE;
  });

  const currentCall = computed(() => {
    if (callState.value === CALL_STATES.INCOMING) {
      return incomingCall.value;
    }
    return activeCall.value || incomingCall.value;
  });

  watch(
    callState,
    newState => {
      if (newState === CALL_STATES.JOINED) {
        durationTimer.start();
      } else {
        durationTimer.stop();
        callDuration.value = 0;
      }
    },
    { immediate: true }
  );

  const handleCallDisconnected = () => {
    callsStore.clearActiveCall();
  };

  onMounted(() => {
    TwilioVoiceClient.addEventListener(
      'call:disconnected',
      handleCallDisconnected
    );
  });

  onUnmounted(() => {
    durationTimer.stop();
    TwilioVoiceClient.removeEventListener(
      'call:disconnected',
      handleCallDisconnected
    );
  });

  const joinCall = async ({ conversationId, inboxId, callSid }) => {
    if (isJoining.value) return null;

    isJoining.value = true;
    try {
      const device = await TwilioVoiceClient.initializeDevice(inboxId);
      // TODO: Handle device initialization failure
      if (!device) {
        return null;
      }

      const joinResponse = await VoiceAPI.joinConference({
        conversationId,
        inboxId,
        callSid,
      });

      const conferenceSid = joinResponse?.conference_sid;
      await TwilioVoiceClient.joinClientCall({
        to: conferenceSid,
        conversationId,
      });

      callsStore.clearIncomingCall();
      callsStore.setActiveCall({
        callSid,
        conversationId,
        inboxId,
        isJoined: true,
      });
      durationTimer.start();

      return { conferenceSid };
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Failed to join call:', error);
      return null;
    } finally {
      isJoining.value = false;
    }
  };

  const endCall = async ({ conversationId, inboxId } = {}) => {
    await VoiceAPI.leaveConference(inboxId, conversationId);
    TwilioVoiceClient.endClientCall();
    durationTimer.stop();
    callsStore.clearActiveCall();
    callsStore.clearIncomingCall();
  };

  const acceptIncomingCall = async ({ inboxId }) => {
    const call = incomingCall.value;

    return joinCall({
      conversationId: call.conversationId,
      inboxId,
      callSid: call.callSid,
    });
  };

  const rejectIncomingCall = () => {
    TwilioVoiceClient.endClientCall();
    callsStore.clearIncomingCall();
  };

  const formattedCallDuration = computed(() => {
    const minutes = Math.floor(callDuration.value / 60);
    const seconds = callDuration.value % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  });

  return {
    // State
    callState,
    CALL_STATES,
    currentCall,
    activeCall,
    incomingCall,
    hasActiveCall,
    hasIncomingCall,
    isOutbound,
    isJoining,
    callDuration,
    formattedCallDuration,
    // Actions
    joinCall,
    endCall,
    acceptIncomingCall,
    rejectIncomingCall,
  };
}
