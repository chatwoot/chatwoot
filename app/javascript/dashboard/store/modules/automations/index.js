import Vue from 'vue';
import types from '../../mutation-types';
import actions from './actions';

const state = {
  automations: [],
  listLoadingStatus: true,
};

// mutations
export const mutations = {
  [types.ADD_AUTOMATION](_state, automation) {
    _state.allConversations = newAllConversations;
  },

  [types.SET_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = true;
  },

  [types.CLEAR_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = false;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
