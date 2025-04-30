import { rejectCall } from '../../api/conversation';

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
  acceptCall({ commit, state,dispatch }, call_data) {
    if (state.activeCall) {
      dispatch('message/updateCallStatus', {
        callStatus: 'accepted',
        messageId: call_data.message_id,
      }, {root: true})
      commit('UPDATE_CALL_STATUS', { call_data, status: 'accepted' });
      commit('SET_CALL_IN_PROGRESS', true);
    }
  },
  rejectCall({ state, dispatch }, call_data) {
    console.log('Active call', state.activeCall);
    console.log('Call data', call_data);
    if (state.activeCall) {

      dispatch('message/updateCallStatus', {
        callStatus: 'rejected',
        messageId: call_data.message_id,
      }, {root: true})

      rejectCall({ room_id: call_data.room_id });
      dispatch('endCall', call_data);
    }
  },
  endCall({ commit, state }, call_data) {
    // NOTE: Unused and Incomplete implementation due to Iframe support lack on customer
    if (state.activeCall) {
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
