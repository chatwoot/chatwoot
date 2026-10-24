import {
  SET_CONVERSATION_ATTRIBUTES,
  UPDATE_CONVERSATION_ATTRIBUTES,
  CLEAR_CONVERSATION_ATTRIBUTES,
} from '../types';
import { getConversationAPI } from '../../api/conversation';
import { setActiveConversationId } from '../../helpers/axios';
import { isMultipleConversationsEnabled } from '../../helpers/utils';

const state = {
  id: '',
  status: '',
};

export const getters = {
  getConversationParams: $state => $state,
};

export const actions = {
  getAttributes: async ({ commit, state: attributes }) => {
    try {
      const { data } = await getConversationAPI();
      if (isMultipleConversationsEnabled() && data.id !== attributes.id) return;
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
  clearConversationAttributes: ({ commit }) => {
    commit('CLEAR_CONVERSATION_ATTRIBUTES');
  },
};

export const mutations = {
  [SET_CONVERSATION_ATTRIBUTES]($state, data) {
    $state.id = data.id;
    $state.status = data.status;
    setActiveConversationId(data.id);
  },
  [UPDATE_CONVERSATION_ATTRIBUTES]($state, data) {
    if (data.id === $state.id) {
      $state.id = data.id;
      $state.status = data.status;
    }
  },
  [CLEAR_CONVERSATION_ATTRIBUTES]($state) {
    $state.id = '';
    $state.status = '';
    setActiveConversationId(null);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
