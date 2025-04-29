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
  setActiveCall({ commit }, callData) {
    if (!callData || !callData.callSid) {
      throw new Error('Invalid call data provided');
    }

    commit('SET_ACTIVE_CALL', callData);

    // Update app state if in browser environment
    if (typeof window !== 'undefined' && window.app?.$data) {
      window.app.$data.showCallWidget = true;
    }
  },

  clearActiveCall({ commit }) {
    commit('CLEAR_ACTIVE_CALL');

    // Update app state if in browser environment
    if (typeof window !== 'undefined' && window.app?.$data) {
      window.app.$data.showCallWidget = false;
    }
  },

  setIncomingCall({ commit, state }, callData) {
    if (!callData || !callData.callSid) {
      throw new Error('Invalid call data provided');
    }
    
    // Don't set as incoming if call is already active
    if (state.activeCall?.callSid === callData.callSid) {
      return;
    }
    
    // Don't set as incoming if call is already incoming
    if (state.incomingCall?.callSid === callData.callSid) {
      return;
    }
    
    commit('SET_INCOMING_CALL', callData);
    
    // Update app state if in browser environment
    if (typeof window !== 'undefined' && window.app && window.app.$data) {
      window.app.$data.showCallWidget = true;
    }
  },

  clearIncomingCall({ commit }) {
    commit('CLEAR_INCOMING_CALL');
  },

  acceptIncomingCall({ commit, state }) {
    const incomingCall = state.incomingCall;
    if (!incomingCall) {
      throw new Error('No incoming call to accept');
    }

    // Move incoming call to active call
    commit('SET_ACTIVE_CALL', {
      ...incomingCall,
      isJoined: true,
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
