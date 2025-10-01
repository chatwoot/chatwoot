import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import VoiceAPI from 'dashboard/api/channels/voice';

export function useCallSession() {
  const store = useStore();
  const isJoining = ref(false);

  const activeCall = computed(() => store.getters['calls/getActiveCall']);
  const incomingCall = computed(() => store.getters['calls/getIncomingCall']);
  const hasActiveCall = computed(() => store.getters['calls/hasActiveCall']);
  const hasIncomingCall = computed(
    () => store.getters['calls/hasIncomingCall']
  );

  const joinCall = async ({
    conversationId,
    inboxId,
    callSid,
    callMeta = {},
  }) => {
    if (isJoining.value) return null;
    if (!conversationId || !inboxId || !callSid) return null;

    isJoining.value = true;
    try {
      await VoiceAPI.initializeDevice(inboxId, { store });
      const joinResponse = await VoiceAPI.joinConference({
        conversation_id: conversationId,
        inbox_id: inboxId,
        call_sid: callSid,
      });

      const conferenceSid = joinResponse?.conference_sid;
      if (conferenceSid) {
        VoiceAPI.joinClientCall({ To: conferenceSid, conversationId });
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
    if (inboxId && conversationId) {
      try {
        await VoiceAPI.leaveConference(inboxId, conversationId);
      } catch (error) {
        // ignore terminate errors
      }
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

  return {
    activeCall,
    incomingCall,
    hasActiveCall,
    hasIncomingCall,
    isJoining,
    joinCall,
    endCall,
    acceptIncomingCall,
    rejectIncomingCall,
  };
}
