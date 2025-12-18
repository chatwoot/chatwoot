import { computed, ref, watch, onUnmounted, onMounted } from 'vue';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import { useCallsStore } from 'dashboard/stores/calls';

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
  const durationTimer = ref(null);

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

  const startDurationTimer = () => {
    if (durationTimer.value) {
      clearInterval(durationTimer.value);
    }
    callDuration.value = 0;
    durationTimer.value = setInterval(() => {
      callDuration.value += 1;
    }, 1000);
  };

  const stopDurationTimer = () => {
    if (durationTimer.value) {
      clearInterval(durationTimer.value);
      durationTimer.value = null;
    }
    callDuration.value = 0;
  };

  watch(
    callState,
    newState => {
      if (newState === CALL_STATES.JOINED) {
        startDurationTimer();
      } else {
        stopDurationTimer();
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
    stopDurationTimer();
    TwilioVoiceClient.removeEventListener(
      'call:disconnected',
      handleCallDisconnected
    );
  });

  const joinCall = async ({
    conversationId,
    inboxId,
    callSid,
    callMeta = {},
  }) => {
    if (isJoining.value) return null;

    isJoining.value = true;
    try {
      const device = await TwilioVoiceClient.initializeDevice(inboxId);
      if (!device) return null;
      const joinResponse = await VoiceAPI.joinConference({
        conversationId,
        inboxId,
        callSid,
      });

      const conferenceSid = joinResponse?.conference_sid;
      if (conferenceSid) {
        await TwilioVoiceClient.joinClientCall({
          To: conferenceSid,
          conversationId,
        });
      }

      callsStore.setActiveCall({
        callSid,
        conversationId,
        inboxId,
        isJoined: true,
        startedAt: Date.now(),
        ...callMeta,
      });
      callsStore.clearIncomingCall();

      return { conferenceSid };
    } finally {
      isJoining.value = false;
    }
  };

  const endCall = async ({ conversationId, inboxId } = {}) => {
    stopDurationTimer();

    if (inboxId && conversationId) {
      await VoiceAPI.leaveConference(inboxId, conversationId);
    }

    TwilioVoiceClient.endClientCall();
    callsStore.clearActiveCall();
    callsStore.clearIncomingCall();
  };

  const acceptIncomingCall = async ({ inboxId }) => {
    const call = incomingCall.value;
    if (!call || !inboxId) return null;
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
