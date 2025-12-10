import VoiceAPI from 'dashboard/api/channels/voice';
import { TERMINAL_STATUSES } from 'dashboard/helper/voice';

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
  handleCallStatusChanged({ dispatch }, { status }) {
    if (TERMINAL_STATUSES.includes(status)) {
      dispatch('clearActiveCall');
      dispatch('clearIncomingCall');
    }
  },

  setActiveCall({ commit, dispatch, state: currentState }, callData) {
    if (!callData?.callSid) return;

    if (callData.status && TERMINAL_STATUSES.includes(callData.status)) {
      if (callData.callSid === currentState.activeCall?.callSid) {
        dispatch('clearActiveCall');
      }
      return;
    }

    commit('SET_ACTIVE_CALL', callData);
  },

  clearActiveCall({ commit }) {
    VoiceAPI.endClientCall();
    commit('CLEAR_ACTIVE_CALL');
  },

  setIncomingCall({ commit, state: currentState }, callData) {
    if (!callData?.callSid) return;
    if (currentState.activeCall?.callSid === callData.callSid) return;
    if (currentState.incomingCall?.callSid === callData.callSid) return;

    commit('SET_INCOMING_CALL', { ...callData, receivedAt: Date.now() });
  },

  clearIncomingCall({ commit }) {
    commit('CLEAR_INCOMING_CALL');
  },

  acceptIncomingCall({ commit, state: currentState }) {
    const incomingCall = currentState.incomingCall;
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
