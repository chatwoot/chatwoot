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
import { handleVoiceCallCreated } from 'dashboard/helper/voice';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import {
  CONTENT_TYPES,
  VOICE_CALL_DIRECTION,
  VOICE_CALL_STATUS,
} from 'dashboard/components-next/message/constants';
import Timer from 'dashboard/helper/Timer';

const isWhatsappCall = call => call?.provider === VOICE_CALL_PROVIDERS.WHATSAPP;

// Dismissed call sids must not be re-seeded by the conversation-load watcher.
// Lives at module scope so all consumers share the same set.
const dismissedCallSids = new Set();
const markDismissed = callSid => {
  if (callSid) dismissedCallSids.add(callSid);
};

// Globals attached once across all useCallSession() consumers — bubbles in a
// long thread call this composable many times, and a per-instance Timer +
// window listener stack would multiply work.
let globalsAttachedCount = 0;
let globalDurationTimer = null;
const globalCallDuration = ref(0);
let storedCallsStoreRef = null;
// Shared join lock so two surfaces (bubble + widget) clicking concurrently
// see one in-flight join, not two unrelated isJoining refs.
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
const handleTwilioDisconnectedGlobal = () =>
  storedCallsStoreRef?.clearActiveCall();

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

// Build the action surface used by both the root session composable and the
// lighter useCallActions consumer. All state is module-scoped — the actions
// don't depend on per-instance refs, so they're cheap to call from anywhere.
const buildCallActions = ({ callsStore, whatsappSession, t }) => {
  const findCall = callSid => callsStore.calls.find(c => c.callSid === callSid);

  const endCall = async ({ conversationId, inboxId, callSid }) => {
    const call = findCall(callSid);
    if (isWhatsappCall(call)) {
      // Pass call.callId so a wiped module state (e.g. a prior accept attempt
      // tore down the WebRTC session) doesn't stop us hitting /terminate.
      await whatsappSession.endActiveCall(call?.callId);
      globalDurationTimer?.stop();
      callsStore.clearActiveCall();
      return;
    }

    // try/finally so a failed leaveConference (e.g. backend 5xx) still
    // tears down the local Device and UI state — otherwise the call stays
    // visually active with the mic open.
    try {
      await VoiceAPI.leaveConference({ inboxId, conversationId, callSid });
    } finally {
      TwilioVoiceClient.endClientCall();
      globalDurationTimer?.stop();
      callsStore.clearActiveCall();
    }
  };

  const joinCall = async ({ conversationId, inboxId, callSid }) => {
    if (globalIsJoining.value) return null;

    const call = findCall(callSid);
    // Outbound *WhatsApp* calls have no separate join step — the offer was
    // sent at initiate time and the answer is applied by the cable handler.
    // Routing through acceptIncomingCall here would call prepareInboundAnswer →
    // cleanup() and destroy the live outbound session. Outbound *Twilio*
    // calls still need joinConference + joinClientCall (FloatingCallWidget
    // auto-joins them), so don't short-circuit those.
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
      if (error?.response?.status === 409) {
        TwilioVoiceClient.endClientCall();
        markDismissed(callSid);
        callsStore.dismissCall(callSid);
      } else if (!isWhatsappCall(call)) {
        // Tear down the Twilio Device on any other join error so a retry
        // starts from a clean state — joinClientCall can leave the device
        // half-initialized after a network blip.
        TwilioVoiceClient.endClientCall();
      }
      // eslint-disable-next-line no-console
      console.error('Failed to join call:', error);
      // Drop any half-built WebRTC state so the next click starts fresh.
      cleanupWhatsappSession();
      return null;
    } finally {
      globalIsJoining.value = false;
    }
  };

  // Await provider-side reject before dismissing the local entry; if the API
  // call fails the call should stay surfaced so the agent can retry instead of
  // disappearing while the backend still rings.
  const rejectIncomingCall = async callSid => {
    const call = findCall(callSid);
    try {
      if (isWhatsappCall(call) && call?.callId) {
        if (call.callDirection === VOICE_CALL_DIRECTION.OUTBOUND) {
          // Outbound calls that are still ringing must be terminated, not
          // rejected (reject is the inbound-side verb on Meta's API).
          await whatsappSession.endActiveCall(call.callId);
        } else {
          await whatsappSession.rejectIncomingCall(call.callId);
        }
      } else if (call?.inboxId && call?.conversationId) {
        // Twilio incoming reject: agent hasn't joined the Device yet, so
        // endClientCall is a no-op. End the conference server-side instead
        // so Twilio hangs up the inbound leg.
        await VoiceAPI.leaveConference({
          inboxId: call.inboxId,
          conversationId: call.conversationId,
          callSid,
        });
      } else {
        TwilioVoiceClient.endClientCall();
      }
    } finally {
      markDismissed(callSid);
      callsStore.dismissCall(callSid);
    }
  };

  const dismissCall = callSid => {
    markDismissed(callSid);
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

// Root-mount composable. Call once at the dashboard root (FloatingCallWidget
// is the natural anchor — always mounted, lifetime spans the whole session).
// This is the only path that registers global window/Twilio listeners and
// owns the duration Timer.
export function useCallSession() {
  const store = useStore();
  const callsStore = useCallsStore();
  const whatsappSession = useWhatsappCallSession();
  const { t } = useI18n();

  const reactive = buildReactiveSurface(callsStore);

  // Cable broadcasts (voice_call.incoming / message.created) are one-shot, so
  // on a hard refresh they leave the calls store empty. Seed it from any
  // ringing voice_call message in the conversation cache. Skip calls the
  // agent has already dismissed locally so they don't re-pop on the next
  // conversation update.
  const seedCallsFromHydratedMessages = () => {
    const conversations = store.getters.getAllConversations || [];
    const currentUserId = store.getters.getCurrentUserID;
    const currentUserAvailability = store.getters.getCurrentUserAvailability;
    conversations.forEach(conv => {
      (conv.messages || []).forEach(msg => {
        if (msg.content_type !== CONTENT_TYPES.VOICE_CALL) return;
        if (msg.call?.status !== VOICE_CALL_STATUS.RINGING) return;
        const callSid = msg.call?.provider_call_id;
        if (callSid && dismissedCallSids.has(callSid)) return;
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

  // Re-seed when conversations stream in after mount; addCall merges by callSid
  // and dismissed sids are filtered, so this is idempotent.
  watch(
    () => store.getters.getAllConversations?.length,
    () => seedCallsFromHydratedMessages()
  );

  onUnmounted(() => detachGlobalsOnLastUnmount());

  const actions = buildCallActions({ callsStore, whatsappSession, t });

  return { ...reactive, ...actions };
}

// Lightweight consumer for components that need to read state and trigger
// actions but should NOT mount global listeners (e.g., per-message bubbles
// rendered in a thread). Reads from the same module-level state that
// useCallSession owns, so the duration timer and dismissed set stay coherent.
export function useCallActions() {
  const callsStore = useCallsStore();
  const whatsappSession = useWhatsappCallSession();
  const { t } = useI18n();

  const reactive = buildReactiveSurface(callsStore);
  const actions = buildCallActions({ callsStore, whatsappSession, t });

  return { ...reactive, ...actions };
}
