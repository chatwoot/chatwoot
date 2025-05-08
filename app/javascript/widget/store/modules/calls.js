import { toRaw } from 'vue';
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
    commit('SET_ACTIVE_CALL', {
      call_data,
      caller,
      status: 'ringing',
    });
  },
  acceptCall({ commit, state,dispatch, rootGetters }, call_data) {
    if (state.activeCall) {
      const messages = rootGetters['conversation/getConversation']

      const message = Object.values(toRaw(messages)).reverse().find(e => e.content_attributes.call_room == call_data.room_id)

      const messageId = message.id;
      dispatch('message/updateCallStatus', {
        callStatus: 'accepted',
        messageId: messageId,
      }, {root: true})
      commit('UPDATE_CALL_STATUS', { call_data, status: 'accepted' });
      commit('SET_CALL_IN_PROGRESS', true);
    }
  },
  rejectCall({ state, dispatch, rootGetters }, call_data) {
    if (state.activeCall) {

      const messages = rootGetters['conversation/getConversation']
    
      const message = Object.values(toRaw(messages)).reverse().find(e => e.content_attributes.call_room == call_data.room_id)

      const messageId = message.id;

      dispatch('message/updateCallStatus', {
        callStatus: 'rejected',
        messageId: messageId,
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
