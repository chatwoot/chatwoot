import ConversationAPI from '../../api/inbox/conversation';

export const initialState = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
};
export const getters = {
  getConversations(state) {
    return state.records;
  },
  getUIFlags(state) {
    return state.uiFlags;
  },
};
export const mutations = {
  setConversation(state, records) {
    state.records = records;
  },
  setUIFlags(state, uiFlags) {
    state.uiFlags = { ...state.uiFlags, ...uiFlags };
  },
};
export const actions = {
  async get({ commit }, { q }) {
    commit('setConversation', []);
    if (!q) {
      return;
    }
    commit('setUIFlags', { isFetching: true });
    try {
      const {
        data: {
          data: { payload },
        },
      } = await ConversationAPI.search({ q });
      commit('setConversation', payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit('setUIFlags', { isFetching: false });
    }
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  actions,
  mutations,
};
