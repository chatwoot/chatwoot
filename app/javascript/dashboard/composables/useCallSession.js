import { computed, ref, watch, onUnmounted } from 'vue';
import { useStore } from 'vuex';
import VoiceAPI from 'dashboard/api/channels/voice';

const CALL_STATES = {
  IDLE: 'idle',
  INCOMING: 'incoming',
  OUTGOING: 'outgoing',
  JOINED: 'joined',
};

export function useCallSession() {
  const store = useStore();
  const isJoining = ref(false);
  const callDuration = ref(0);
  const durationTimer = ref(null);

  const activeCall = computed(() => store.getters['calls/getActiveCall']);
  const incomingCall = computed(() => store.getters['calls/getIncomingCall']);
  const hasActiveCall = computed(() => store.getters['calls/hasActiveCall']);
  const hasIncomingCall = computed(
    () => store.getters['calls/hasIncomingCall']
  );

  const isJoined = computed(() => activeCall.value?.isJoined === true);

  const callState = computed(() => {
    if (isJoined.value) return CALL_STATES.JOINED;
    if (hasIncomingCall.value && incomingCall.value?.isOutbound) {
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

  onUnmounted(() => {
    stopDurationTimer();
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
      const device = await VoiceAPI.initializeDevice(inboxId, { store });
      if (!device) return null;
      const joinResponse = await VoiceAPI.joinConference({
        conversationId,
        inboxId,
        callSid,
      });

      const conferenceSid = joinResponse?.conference_sid;
      if (conferenceSid) {
        await VoiceAPI.joinClientCall({ To: conferenceSid, conversationId });
      }

      store.dispatch('calls/setActiveCall', {
        callSid,
        conversationId,
        inboxId,
        isJoined: true,
        startedAt: Date.now(),
        ...callMeta,
      });
      store.dispatch('calls/clearIncomingCall');

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

    VoiceAPI.endClientCall();
    store.dispatch('calls/clearActiveCall');
    store.dispatch('calls/clearIncomingCall');
  };

  const acceptIncomingCall = async (call = incomingCall.value) => {
    if (!call) return null;
    return joinCall({
      conversationId: call.conversationId,
      inboxId: call.inboxId,
      callSid: call.callSid,
      callMeta: call,
    });
  };

  const rejectIncomingCall = () => {
    VoiceAPI.endClientCall();
    store.dispatch('calls/clearIncomingCall');
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
