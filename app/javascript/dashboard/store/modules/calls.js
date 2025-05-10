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
  // This action will handle both message updates and direct call status changes
  /**
   * Handles all call status changes from ActionCable.
   * Closes the widget and clears state for terminal statuses.
   * Only this action should manipulate widget visibility for call end.
   */
  handleCallStatusChanged({ state, dispatch }, { callSid, status }) {
    // Debug logging for conference call widget close issue
    // eslint-disable-next-line no-console
    console.log('[CALL DEBUG] handleCallStatusChanged invoked', { callSid, status, activeCall: state.activeCall });
    const isActiveCall = callSid === state.activeCall?.callSid;
    const terminalStatuses = [
      'ended',
      'missed',
      'completed',
      'failed',
      'busy',
      'no_answer',
    ];
    if (isActiveCall && terminalStatuses.includes(status)) {
    // eslint-disable-next-line no-console
    console.log('[CALL DEBUG] Terminal status match. Closing widget.', { callSid, status, activeCall: state.activeCall });
      // Clean up active call state
      dispatch('clearActiveCall');
      // Hide floating widget reactively
      if (window.app && window.app.$data) {
        window.app.$data.showCallWidget = false;
      }
      // Emit event for any listeners
      if (window.app) {
        window.app.$emit('callEnded');
      }
      // Outbound call cleanup
      if (state.activeCall?.isOutbound && window.globalCallStatus) {
        window.globalCallStatus.active = false;
        window.globalCallStatus.incoming = false;
      }
    }
  },

  setActiveCall({ commit, dispatch, state }, callData) {
    if (!callData || !callData.callSid) {
      throw new Error('Invalid call data provided');
    }
    
    // If the call has a status, check if it's a terminal status
    if (callData.status && ['ended', 'missed', 'completed'].includes(callData.status)) {
      // If the call is already in a terminal state, clear any active call
      if (callData.callSid === state.activeCall?.callSid) {
        return dispatch('clearActiveCall');
      }
      // Otherwise just ignore it - don't set an already ended call as active
      return;
    }

    commit('SET_ACTIVE_CALL', callData);

    // Update app state if in browser environment
    if (typeof window !== 'undefined' && window.app?.$data) {
      window.app.$data.showCallWidget = true;
    }
  },

  clearActiveCall({ commit }) {
    // Store the messageId before clearing the call
    const messageId = state.activeCall?.messageId;
    
    commit('CLEAR_ACTIVE_CALL');

    // Update app state if in browser environment
    if (typeof window !== 'undefined' && window.app?.$data) {
      window.app.$data.showCallWidget = false;
    }
    
    // We no longer need to update call widget status as we'll use reactive Vue props
    // and updates will come through Chatwoot's standard message update events
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
    
    const enrichedCallData = {
      ...callData,
      receivedAt: Date.now(),
    };
    
    commit('SET_INCOMING_CALL', enrichedCallData);
    
    // Update app state if in browser environment
    if (typeof window !== 'undefined' && window.app && window.app.$data) {
      window.app.$data.showCallWidget = true;
    }
    
    // We no longer need to update call widget status as we'll use reactive Vue props
    // and updates will come through Chatwoot's standard message update events
  },

  clearIncomingCall({ commit }) {
    // Store the messageId before clearing the call
    const messageId = state.incomingCall?.messageId;
    
    commit('CLEAR_INCOMING_CALL');
    
    // We no longer need to update call widget status as we'll use reactive Vue props
    // and updates will come through Chatwoot's standard message update events
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
      startedAt: Date.now(),
    });
    commit('CLEAR_INCOMING_CALL');
    
    // We no longer need to update call widget status as we'll use reactive Vue props
    // and updates will come through Chatwoot's standard message update events
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
  // We no longer need to update call widget status as we'll use reactive Vue props
  
  // We no longer need subscription mutations
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
