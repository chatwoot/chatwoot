import {
  SET_CONVERSATION_ATTRIBUTES,
  UPDATE_CONVERSATION_ATTRIBUTES,
} from '../types';
import { getConversationAPI } from '../../api/conversation';

const state = {
  id: '',
  status: '',
};

export const getters = {
  getConversationParams: $state => $state,
};

export const actions = {
  get: async ({ commit }) => {
    try {
      const { data } = await getConversationAPI();
      const { contact_last_seen_at: lastSeen } = data;
      commit(SET_CONVERSATION_ATTRIBUTES, data);
      commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
    } catch (error) {
      // Ignore error
    }
  },
  update({ commit }, data) {
    commit(UPDATE_CONVERSATION_ATTRIBUTES, data);
  },
};

export const mutations = {
  [SET_CONVERSATION_ATTRIBUTES]($state, data) {
    $state.id = data.id;
    $state.status = data.status;
  },
  [UPDATE_CONVERSATION_ATTRIBUTES]($state, data) {
    if (data.id === $state.id) {
      $state.id = data.id;
      $state.status = data.status;
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
