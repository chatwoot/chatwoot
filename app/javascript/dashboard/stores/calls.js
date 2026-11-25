import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import { cleanupWhatsappSession } from 'dashboard/composables/useWhatsappCallSession';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';
import { VOICE_CALL_STATUS } from 'dashboard/components-next/message/constants';
import { TERMINAL_STATUSES } from 'dashboard/helper/voice';
import { defineStore } from 'pinia';

const teardownByProvider = call => {
  if (call?.provider === VOICE_CALL_PROVIDERS.WHATSAPP) {
    cleanupWhatsappSession();
  } else {
    TwilioVoiceClient.endClientCall();
  }
};

export const useCallsStore = defineStore('calls', {
  state: () => ({
    calls: [],
    // Statuses that arrived before their call was added, e.g. an outbound call
    // answered before its created event; addCall applies them
    pendingStatuses: {},
  }),

  getters: {
    activeCall: state => state.calls.find(call => call.isActive) || null,
    hasActiveCall: state => state.calls.some(call => call.isActive),
    incomingCalls: state => state.calls.filter(call => !call.isActive),
    hasIncomingCall: state => state.calls.some(call => !call.isActive),
  },

  actions: {
    handleCallStatusChanged({ callSid, status }) {
      const call = this.calls.find(c => c.callSid === callSid);
      if (!TERMINAL_STATUSES.includes(status)) {
        // A connected call never rings again, so a late ringing update is stale
        const current = call ? call.status : this.pendingStatuses[callSid];
        if (
          status === VOICE_CALL_STATUS.RINGING &&
          current === VOICE_CALL_STATUS.IN_PROGRESS
        )
          return;
        if (call) call.status = status;
        else this.pendingStatuses[callSid] = status;
        return;
      }
      delete this.pendingStatuses[callSid];

      // WhatsApp recordings live in the in-memory recorder until voice_call.ended
      // uploads them; tearing down here would race-wipe those chunks.
      if (call?.provider === 'whatsapp') {
        this.calls = this.calls.filter(c => c.callSid !== callSid);
        return;
      }

      this.removeCall(callSid);
    },

    addCall(callData) {
      if (!callData?.callSid) return;
      const existing = this.calls.find(c => c.callSid === callData.callSid);
      if (existing) {
        // Merge so a later cable event with sdp_offer/provider/caller fills in
        // gaps left by the earlier message.created path (and vice versa).
        // Preserve a previously-captured caller snapshot when the incoming
        // event has no sender info, otherwise the widget would flip to
        // "Unknown caller" on the next status update.
        const next = { ...callData };
        if (existing.caller && !next.caller) delete next.caller;
        Object.assign(existing, next, { isActive: existing.isActive });
        return;
      }

      const status = this.pendingStatuses[callData.callSid];
      delete this.pendingStatuses[callData.callSid];
      // Prepend so the newest call surfaces as the primary card (incomingCalls[0])
      // and older calls drop into the stack below it.
      this.calls.unshift({
        ...callData,
        ...(status && { status }),
        isActive: false,
      });
    },

    removeCall(callSid) {
      const callToRemove = this.calls.find(c => c.callSid === callSid);
      if (callToRemove?.isActive) {
        teardownByProvider(callToRemove);
      }
      this.calls = this.calls.filter(c => c.callSid !== callSid);
    },

    setCallActive(callSid) {
      this.calls = this.calls.map(call => ({
        ...call,
        isActive: call.callSid === callSid,
        onHold: false,
      }));
    },

    // Flipped only after Twilio confirmed the hold, so the card never shows a hold that failed
    setCallOnHold(callSid, onHold) {
      const call = this.calls.find(c => c.callSid === callSid);
      if (call) call.onHold = onHold;
    },

    clearActiveCall() {
      const active = this.calls.find(c => c.isActive);
      teardownByProvider(active);
      this.calls = this.calls.filter(call => !call.isActive);
    },

    dismissCall(callSid) {
      this.calls = this.calls.filter(call => call.callSid !== callSid);
    },

    removeCallsForConversation(conversationId) {
      const callsToRemove = this.calls.filter(
        call => call.conversationId === conversationId
      );

      // Tear down each active call via its own provider so a WhatsApp call
      // gets cleanupWhatsappSession() (closes pc, stops recorder/mic) instead
      // of the Twilio-only endClientCall() — otherwise mic stays open.
      callsToRemove.filter(call => call.isActive).forEach(teardownByProvider);

      this.calls = this.calls.filter(
        call => call.conversationId !== conversationId
      );
    },
  },
});
