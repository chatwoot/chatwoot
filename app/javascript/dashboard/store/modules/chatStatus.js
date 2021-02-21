import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ChatStatusItemsAPI from '../../api/chat_status_items';

export const state = {
  records: [],
};

export const getters = {
  getChatStatusItems(_state) {
    return _state.records;
  },
};

export const actions = {
  get: async function getChatStatusItems({ commit }) {
    try {
      const response = await ChatStatusItemsAPI.get();
      commit(types.SET_STATUS, response.data.payload);
    } catch (error) {
      // Ignore error
    }
  },
};

export const mutations = {
  [types.SET_STATUS]: MutationHelpers.set,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
