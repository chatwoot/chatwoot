const state = {
  activeCall: null,
  isCallInProgress: false,
};

export const getters = {
  getActiveCall: $state => $state.activeCall,
  hasActiveCall: $state => !!$state.activeCall,
  isCallInProgress: $state => $state.isCallInProgress,
};

export const actions = {
  receiveCall({ commit }, { call_data, caller }) {
    console.log('receiveCall', call_data, caller);
    commit('SET_ACTIVE_CALL', { 
      call_data, 
      caller, 
      status: 'ringing',
    });
  },
  acceptCall({ commit, state }, call_data) {
    if (state.activeCall && state.activeCall.roomId === call_data.roomId) {
      commit('UPDATE_CALL_STATUS', { call_data, status: 'accepted' });
      commit('SET_CALL_IN_PROGRESS', true);
    }
  },
  rejectCall({ commit, state }, call_data) {
    if (state.activeCall && state.activeCall.roomId === call_data.roomId) {
      commit('UPDATE_CALL_STATUS', { call_data, status: 'rejected' });
      commit('SET_ACTIVE_CALL', null);
    }
  },
  endCall({ commit, state }, call_data) {
    if (state.activeCall && state.activeCall.roomId === call_data.roomId) {
      commit('UPDATE_CALL_STATUS', { call_data, status: 'ended' });
      commit('SET_ACTIVE_CALL', null);
      commit('SET_CALL_IN_PROGRESS', false);
    }
  },
};

export const mutations = {
  SET_ACTIVE_CALL($state, call_data) {
    $state.activeCall = call_data;
  },
  UPDATE_CALL_STATUS($state, { call_data, status }) {
    if ($state.activeCall && $state.activeCall.roomId === call_data.roomId) {
      $state.activeCall = {
        ...$state.activeCall,
        status,
      };
    }
  },
  SET_CALL_IN_PROGRESS($state, inProgress) {
    $state.isCallInProgress = inProgress;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
}; 