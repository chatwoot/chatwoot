import { computed, ref, watch, onUnmounted, onMounted } from 'vue';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import { useCallsStore } from 'dashboard/stores/calls';
import Timer from 'dashboard/helper/Timer';

export function useCallSession() {
  const callsStore = useCallsStore();
  const isJoining = ref(false);
  const callDuration = ref(0);
  const durationTimer = new Timer(elapsed => {
    callDuration.value = elapsed;
  });

  const activeCall = computed(() => callsStore.activeCall);
  const incomingCalls = computed(() => callsStore.incomingCalls);
  const hasActiveCall = computed(() => callsStore.hasActiveCall);

  watch(
    hasActiveCall,
    active => {
      if (active) {
        durationTimer.start();
      } else {
        durationTimer.stop();
        callDuration.value = 0;
      }
    },
    { immediate: true }
  );

  onMounted(() => {
    TwilioVoiceClient.addEventListener('call:disconnected', () =>
      callsStore.clearActiveCall()
    );
  });

  onUnmounted(() => {
    durationTimer.stop();
    TwilioVoiceClient.removeEventListener('call:disconnected', () =>
      callsStore.clearActiveCall()
    );
  });

  const endCall = async ({ conversationId, inboxId }) => {
    await VoiceAPI.leaveConference(inboxId, conversationId);
    TwilioVoiceClient.endClientCall();
    durationTimer.stop();
    callsStore.clearActiveCall();
  };

  const joinCall = async ({ conversationId, inboxId, callSid }) => {
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

      await TwilioVoiceClient.joinClientCall({
        to: joinResponse?.conference_sid,
        conversationId,
      });

      callsStore.setCallActive(callSid);
      durationTimer.start();

      return { conferenceSid: joinResponse?.conference_sid };
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Failed to join call:', error);
      return null;
    } finally {
      isJoining.value = false;
    }
  };

  const rejectIncomingCall = callSid => {
    TwilioVoiceClient.endClientCall();
    callsStore.dismissCall(callSid);
  };

  const dismissCall = callSid => {
    callsStore.dismissCall(callSid);
  };

  const formattedCallDuration = computed(() => {
    const minutes = Math.floor(callDuration.value / 60);
    const seconds = callDuration.value % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  });

  return {
    activeCall,
    incomingCalls,
    hasActiveCall,
    isJoining,
    formattedCallDuration,
    joinCall,
    endCall,
    rejectIncomingCall,
    dismissCall,
  };
}
