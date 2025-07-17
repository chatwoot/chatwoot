import VoiceAPI from 'dashboard/api/channels/voice';

const state = {
  activeCall: null,
  incomingCall: null,
};

const getters = {
  getActiveCall: $state => $state.activeCall,
  hasActiveCall: $state => !!$state.activeCall,
  getIncomingCall: $state => $state.incomingCall,
  hasIncomingCall: $state => !!$state.incomingCall,
};

const actions = {
  handleCallStatusChanged({ state, dispatch }, { callSid, status, conversationId }) {
    const isActiveCall = callSid === state.activeCall?.callSid;
    const isIncomingCall = callSid === state.incomingCall?.callSid;
    const terminalStatuses = ['ended', 'missed', 'completed', 'failed', 'busy', 'no_answer'];
    
    if (terminalStatuses.includes(status)) {
      if (isActiveCall) {
        dispatch('clearActiveCall');
      } else if (isIncomingCall) {
        dispatch('clearIncomingCall');
      }
      
      // Hide widget for any terminal status if it matches our call
      if (isActiveCall || isIncomingCall) {
        if (window.app?.$data) {
          window.app.$data.showCallWidget = false;
        }
      }
    }
  },

  setActiveCall({ commit, dispatch, state }, callData) {
    if (!callData?.callSid) return;

    if (callData.status && ['ended', 'missed', 'completed'].includes(callData.status)) {
      if (callData.callSid === state.activeCall?.callSid) {
        return dispatch('clearActiveCall');
      }
      return;
    }

    commit('SET_ACTIVE_CALL', callData);
    if (window.app?.$data) {
      window.app.$data.showCallWidget = true;
    }
  },

  clearActiveCall({ commit }) {
    // End the WebRTC connection before clearing the call state
    try {
      VoiceAPI.endClientCall();
    } catch (error) {
      console.warn('Error ending client call during clearActiveCall:', error);
    }
    
    commit('CLEAR_ACTIVE_CALL');
    if (window.app?.$data) {
      window.app.$data.showCallWidget = false;
    }
  },

  setIncomingCall({ commit, state }, callData) {
    if (!callData?.callSid) return;
    if (state.activeCall?.callSid === callData.callSid) return;
    if (state.incomingCall?.callSid === callData.callSid) return;

    commit('SET_INCOMING_CALL', { ...callData, receivedAt: Date.now() });
    if (window.app?.$data) {
      window.app.$data.showCallWidget = true;
    }
  },

  clearIncomingCall({ commit }) {
    commit('CLEAR_INCOMING_CALL');
  },

  acceptIncomingCall({ commit, state }) {
    const incomingCall = state.incomingCall;
    if (!incomingCall) return;

    commit('SET_ACTIVE_CALL', {
      ...incomingCall,
      isJoined: true,
      startedAt: Date.now(),
    });
    commit('CLEAR_INCOMING_CALL');
  },
};

const mutations = {
  SET_ACTIVE_CALL($state, callData) {
    $state.activeCall = callData;
  },
  CLEAR_ACTIVE_CALL($state) {
    $state.activeCall = null;
  },
  SET_INCOMING_CALL($state, callData) {
    $state.incomingCall = callData;
  },
  CLEAR_INCOMING_CALL($state) {
    $state.incomingCall = null;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
