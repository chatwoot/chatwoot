import { defineStore } from 'pinia';
import TwilioVoiceClient from 'dashboard/api/channel/voice/twilioVoiceClient';
import { TERMINAL_STATUSES } from 'dashboard/helper/voice';

export const useCallsStore = defineStore('calls', {
  state: () => ({
    activeCall: null,
    incomingCall: null,
  }),

  getters: {
    getActiveCall: state => state.activeCall,
    hasActiveCall: state => !!state.activeCall,
    getIncomingCall: state => state.incomingCall,
    hasIncomingCall: state => !!state.incomingCall,
  },

  actions: {
    handleCallStatusChanged({ status }) {
      if (TERMINAL_STATUSES.includes(status)) {
        this.clearActiveCall();
        this.clearIncomingCall();
      }
    },

    setActiveCall(callData) {
      if (!callData?.callSid) return;

      if (callData.status && TERMINAL_STATUSES.includes(callData.status)) {
        if (callData.callSid === this.activeCall?.callSid) {
          this.clearActiveCall();
        }
        return;
      }

      this.activeCall = callData;
    },

    clearActiveCall() {
      TwilioVoiceClient.endClientCall();
      this.activeCall = null;
    },

    setIncomingCall(callData) {
      if (!callData?.callSid) return;
      if (this.activeCall?.callSid === callData.callSid) return;
      if (this.incomingCall?.callSid === callData.callSid) return;

      this.incomingCall = { ...callData, receivedAt: Date.now() };
    },

    clearIncomingCall() {
      this.incomingCall = null;
    },

    acceptIncomingCall() {
      const incomingCall = this.incomingCall;
      if (!incomingCall) return;

      this.activeCall = {
        ...incomingCall,
        isJoined: true,
        startedAt: Date.now(),
      };
      this.incomingCall = null;
    },
  },
});
