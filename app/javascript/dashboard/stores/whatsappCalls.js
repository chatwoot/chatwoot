import { defineStore } from 'pinia';

export const useWhatsappCallsStore = defineStore('whatsappCalls', {
  state: () => ({
    // Incoming ringing calls waiting for agent action
    incomingCalls: [],
    // The single active call (accepted + audio connected)
    activeCall: null,
  }),

  getters: {
    hasIncomingCall: state => state.incomingCalls.length > 0,
    hasActiveCall: state => state.activeCall !== null,
    firstIncomingCall: state => state.incomingCalls[0] || null,
  },

  actions: {
    addIncomingCall(callData) {
      const exists = this.incomingCalls.some(c => c.callId === callData.callId);
      if (exists) return;
      this.incomingCalls.push(callData);
    },

    removeIncomingCall(callId) {
      this.incomingCalls = this.incomingCalls.filter(c => c.callId !== callId);
    },

    setActiveCall(callData) {
      this.activeCall = callData;
    },

    clearActiveCall() {
      this.activeCall = null;
    },

    handleCallAcceptedByOther(callId) {
      // Another agent accepted — remove from incoming list for this agent
      this.removeIncomingCall(callId);
    },

    handleCallEnded(callId) {
      this.removeIncomingCall(callId);
      if (this.activeCall?.callId === callId) {
        this.activeCall = null;
      }
    },
  },
});
