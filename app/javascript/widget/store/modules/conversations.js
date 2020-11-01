import Vue from 'vue';
import { getConversationAPI } from '../../api/conversation';
import { SET_CONVERSATIONS, SET_CONVERSATIONS_UI_FLAGS } from '../types';

const initialState = {
  conversations: {},
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  sortedConversations: ({ conversations }) =>
    Object.values(conversations).sort((a, b) => b.timestamp - a.timestamp),
  getUIFlags: ({ uiFlags }) => uiFlags,
};

export const actions = {
  get: async ({ commit, dispatch }) => {
    try {
      commit(SET_CONVERSATIONS_UI_FLAGS, { isFetching: true });
      const { data } = await getConversationAPI();
      commit(SET_CONVERSATIONS, data);
      data.forEach(conversation => {
        dispatch('conversation/addMessage', conversation.messages[0], {
          root: true,
        });
      });
    } catch (error) {
      // Ignore error
    } finally {
      commit(SET_CONVERSATIONS_UI_FLAGS, { isFetching: false });
    }
  },
};

export const mutations = {
  [SET_CONVERSATIONS_UI_FLAGS](state, data) {
    state.uiFlags = {
      ...state.uiFlags,
      ...data,
    };
  },
  [SET_CONVERSATIONS](state, conversations) {
    const conversationsMap = conversations.reduce((acc, conversation) => {
      return {
        ...acc,
        [conversation.id]: conversation,
      };
    }, {});
    Vue.set(state, 'conversations', conversationsMap);
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  actions,
  mutations,
};
