import { defineStore } from 'pinia';

export const useWhatsappCallsStore = defineStore('whatsappCalls', {
  state: () => ({
    // Incoming ringing calls waiting for agent action
    incomingCalls: [],
    // The single active call (accepted + audio connected)
    activeCall: null,
    // Cleanup callback registered by the composable — called when a call ends externally
    _cleanupCallback: null,
  }),

  getters: {
    hasIncomingCall: state => state.incomingCalls.length > 0,
    hasActiveCall: state => state.activeCall !== null,
    hasWhatsappCall: state =>
      state.incomingCalls.length > 0 || state.activeCall !== null,
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

    registerCleanupCallback(callback) {
      this._cleanupCallback = callback;
    },

    handleCallAcceptedByOther(callId) {
      this.removeIncomingCall(callId);
    },

    handleCallEnded(callId) {
      this.removeIncomingCall(callId);
      if (this.activeCall?.callId === callId) {
        this.activeCall = null;
        // Trigger WebRTC cleanup via the registered callback
        if (this._cleanupCallback) {
          this._cleanupCallback();
        }
      }
      // Also clean up outbound call globals if they match
      if (window.__outboundCallId === callId) {
        if (window.__outboundCallPC) window.__outboundCallPC.close();
        if (window.__outboundCallStream)
          window.__outboundCallStream.getTracks().forEach(t => t.stop());
        if (window.__outboundCallAudio) {
          window.__outboundCallAudio.srcObject = null;
          window.__outboundCallAudio.remove();
        }
        window.__outboundCallPC = null;
        window.__outboundCallStream = null;
        window.__outboundCallAudio = null;
        window.__outboundCallId = null;
      }
    },
  },
});
