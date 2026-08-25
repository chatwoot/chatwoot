import { computed, readonly, ref, watch, onUnmounted, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import { useCallsStore } from 'dashboard/stores/calls';
import { useAlert } from 'dashboard/composables';
import {
  useWhatsappCallSession,
  sendWhatsappTerminateBeacon,
  cleanupWhatsappSession,
} from 'dashboard/composables/useWhatsappCallSession';
import {
  handleVoiceCallCreated,
  markCallDismissed,
  markLocalCall,
  clearLocalCall,
} from 'dashboard/helper/voice';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import {
  CONTENT_TYPES,
  VOICE_CALL_DIRECTION,
  VOICE_CALL_STATUS,
} from 'dashboard/components-next/message/constants';
import Timer from 'dashboard/helper/Timer';

const isWhatsappCall = call => call?.provider === VOICE_CALL_PROVIDERS.WHATSAPP;

let globalsAttachedCount = 0;
let globalDurationTimer = null;
const globalCallDuration = ref(0);
let storedCallsStoreRef = null;
const globalIsJoining = ref(false);
const globalIsJoiningReadonly = readonly(globalIsJoining);

const handleBeforeUnloadGlobal = event => {
  const store = storedCallsStoreRef;
  if (!store) return;
  if (!store.hasActiveCall && !store.hasIncomingCall) return;
  event.preventDefault();
  event.returnValue = '';
};
const handlePageHideGlobal = () => sendWhatsappTerminateBeacon();
const handleTwilioDisconnectedGlobal = () => {
  const activeCall = storedCallsStoreRef?.activeCall;
  if (activeCall?.teardownFailed) return;
  storedCallsStoreRef?.clearActiveCall();
};

const attachGlobalsOnFirstMount = callsStore => {
  globalsAttachedCount += 1;
  if (globalsAttachedCount > 1) return;
  storedCallsStoreRef = callsStore;
  globalDurationTimer = new Timer(elapsed => {
    globalCallDuration.value = elapsed;
  });
  TwilioVoiceClient.addEventListener(
    'call:disconnected',
    handleTwilioDisconnectedGlobal
  );
  window.addEventListener('beforeunload', handleBeforeUnloadGlobal);
  window.addEventListener('pagehide', handlePageHideGlobal);
};

const detachGlobalsOnLastUnmount = () => {
  globalsAttachedCount -= 1;
  if (globalsAttachedCount > 0) return;
  globalDurationTimer?.stop();
  globalDurationTimer = null;
  globalCallDuration.value = 0;
  storedCallsStoreRef = null;
  TwilioVoiceClient.removeEventListener(
    'call:disconnected',
    handleTwilioDisconnectedGlobal
  );
  window.removeEventListener('beforeunload', handleBeforeUnloadGlobal);
  window.removeEventListener('pagehide', handlePageHideGlobal);
};

const buildCallActions = ({ callsStore, whatsappSession, t }) => {
  const findCall = callSid => callsStore.calls.find(c => c.callSid === callSid);

  const endCall = async ({ conversationId, inboxId, callSid }) => {
    const call = findCall(callSid);
    if (isWhatsappCall(call)) {
      await whatsappSession.endActiveCall(call?.callId);
      globalDurationTimer?.stop();
      callsStore.clearActiveCall();
      return;
    }

    const agentCallSid = TwilioVoiceClient.activeCallSid;
    try {
      await VoiceAPI.leaveConference({
        inboxId,
        conversationId,
        callSid,
        agentCallSid,
      });
      globalDurationTimer?.stop();
      callsStore.clearActiveCall();
      clearLocalCall(callSid);
    } catch (error) {
      const terminationInProgress =
        error?.response?.status === 423 &&
        error?.response?.data?.code === 'call_termination_in_progress';

      // Another teardown already owns this Call. Keep this tab's Twilio leg
      // connected and untouched: disconnecting it would emit an unsuppressed
      // participant-leave if the owning teardown later fails.
      if (terminationInProgress) throw error;

      callsStore.markCallTeardownFailed(callSid);
      TwilioVoiceClient.endClientCall();
      globalDurationTimer?.stop();
      clearLocalCall(callSid);
      throw error;
    }
  };

  const joinCall = async ({ conversationId, inboxId, callSid }) => {
    if (globalIsJoining.value) return null;

    const call = findCall(callSid);
    if (
      call?.callDirection === VOICE_CALL_DIRECTION.OUTBOUND &&
      isWhatsappCall(call)
    ) {
      return null;
    }

    globalIsJoining.value = true;
    try {
      if (isWhatsappCall(call)) {
        await whatsappSession.acceptIncomingCall({
          callId: call.callId,
          sdpOffer: call.sdpOffer,
          iceServers: call.iceServers,
        });
        callsStore.setCallActive(callSid);
        globalDurationTimer?.start();
        return { callId: call.callId };
      }

      const device = await TwilioVoiceClient.initializeDevice(inboxId);
      if (!device) return null;

      markLocalCall(callSid);

      const joinResponse = await VoiceAPI.joinConference({
        conversationId,
        inboxId,
        callSid,
      });

      await TwilioVoiceClient.joinClientCall({
        to: joinResponse?.conference_sid,
        conversationId,
        callSid,
      });

      callsStore.setCallActive(callSid);
      globalDurationTimer?.start();

      return { conferenceSid: joinResponse?.conference_sid };
    } catch (error) {
      useAlert(error?.response?.data?.error || t('CONTACT_PANEL.CALL_FAILED'));
      if (!isWhatsappCall(call)) clearLocalCall(callSid);
      if (error?.response?.status === 409) {
        TwilioVoiceClient.endClientCall();
        markCallDismissed(callSid);
        callsStore.dismissCall(callSid);
      } else if (!isWhatsappCall(call)) {
        TwilioVoiceClient.endClientCall();
      }
      // eslint-disable-next-line no-console
      console.error('Failed to join call:', error);
      cleanupWhatsappSession();
      return null;
    } finally {
      globalIsJoining.value = false;
    }
  };

  const rejectIncomingCall = async callSid => {
    const call = findCall(callSid);
    if (isWhatsappCall(call) && call?.callId) {
      if (call.callDirection === VOICE_CALL_DIRECTION.OUTBOUND) {
        await whatsappSession.endActiveCall(call.callId);
      } else {
        await whatsappSession.rejectIncomingCall(call.callId);
      }
    } else if (call?.inboxId && call?.conversationId) {
      await VoiceAPI.leaveConference({
        inboxId: call.inboxId,
        conversationId: call.conversationId,
        callSid,
      });
    } else {
      TwilioVoiceClient.endClientCall();
    }

    markCallDismissed(callSid);
    callsStore.dismissCall(callSid);
  };

  const dismissCall = callSid => {
    markCallDismissed(callSid);
    callsStore.dismissCall(callSid);
  };

  return { endCall, joinCall, rejectIncomingCall, dismissCall };
};

const buildReactiveSurface = callsStore => {
  const activeCall = computed(() => callsStore.activeCall);
  const incomingCalls = computed(() => callsStore.incomingCalls);
  const hasActiveCall = computed(() => callsStore.hasActiveCall);
  const formattedCallDuration = computed(() => {
    const total = globalCallDuration.value;
    const minutes = Math.floor(total / 60);
    const seconds = total % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  });
  return {
    activeCall,
    incomingCalls,
    hasActiveCall,
    isJoining: globalIsJoiningReadonly,
    formattedCallDuration,
  };
};

export function useCallSession() {
  const store = useStore();
  const callsStore = useCallsStore();
  const whatsappSession = useWhatsappCallSession();
  const { t } = useI18n();

  const reactive = buildReactiveSurface(callsStore);

  const seedCallsFromHydratedMessages = () => {
    const conversations = store.getters.getAllConversations || [];
    const currentUserId = store.getters.getCurrentUserID;
    const currentUserAvailability = store.getters.getCurrentUserAvailability;
    conversations.forEach(conv => {
      (conv.messages || []).forEach(msg => {
        if (msg.content_type !== CONTENT_TYPES.VOICE_CALL) return;
        if (msg.call?.status !== VOICE_CALL_STATUS.RINGING) return;
        handleVoiceCallCreated(msg, currentUserId, currentUserAvailability);
      });
    });
  };

  watch(
    reactive.hasActiveCall,
    active => {
      if (active) {
        globalDurationTimer?.start();
      } else {
        globalDurationTimer?.stop();
        globalCallDuration.value = 0;
      }
    },
    { immediate: true }
  );

  onMounted(() => {
    attachGlobalsOnFirstMount(callsStore);
    seedCallsFromHydratedMessages();
  });

  watch(
    () => store.getters.getAllConversations?.length,
    () => seedCallsFromHydratedMessages()
  );

  onUnmounted(() => detachGlobalsOnLastUnmount());

  const actions = buildCallActions({ callsStore, whatsappSession, t });

  return { ...reactive, ...actions };
}

export function useCallActions() {
  const callsStore = useCallsStore();
  const whatsappSession = useWhatsappCallSession();
  const { t } = useI18n();

  const reactive = buildReactiveSurface(callsStore);
  const actions = buildCallActions({ callsStore, whatsappSession, t });

  return { ...reactive, ...actions };
}
