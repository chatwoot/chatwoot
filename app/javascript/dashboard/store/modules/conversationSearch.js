import SearchAPI from '../../api/search';
import types from '../mutation-types';
export const initialState = {
  records: [],
  contactRecords: [],
  conversationRecords: [],
  messageRecords: [],
  messageMeta: {
    currentPage: 1,
    totalCount: 0,
    totalPages: 0,
  },
  uiFlags: {
    isFetching: false,
    isSearchCompleted: false,
    contact: { isFetching: false },
    conversation: { isFetching: false },
    message: { isFetching: false },
  },
};

export const getters = {
  getConversations(state) {
    return state.records;
  },
  getContactRecords(state) {
    return state.contactRecords;
  },
  getConversationRecords(state) {
    return state.conversationRecords;
  },
  getMessageRecords(state) {
    return state.messageRecords;
  },
  getMessageMeta(state) {
    return state.messageMeta;
  },
  getUIFlags(state) {
    return state.uiFlags;
  },
};

export const actions = {
  async get({ commit }, { q }) {
    commit(types.SEARCH_CONVERSATIONS_SET, []);
    if (!q) {
      return;
    }
    commit(types.SEARCH_CONVERSATIONS_SET_UI_FLAG, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await SearchAPI.get({ q });
      commit(types.SEARCH_CONVERSATIONS_SET, payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SEARCH_CONVERSATIONS_SET_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  async fullSearch({ commit, dispatch }, { q, type }) {
    if (!q) {
      return;
    }
    commit(types.FULL_SEARCH_SET_UI_FLAG, {
      isFetching: true,
      isSearchCompleted: false,
    });
    const searchActions = {
      messages: () => dispatch('messageSearch', { q }),
      contacts: () => dispatch('contactSearch', { q }),
      conversations: () => dispatch('conversationSearch', { q }),
      default: () =>
        Promise.all([
          dispatch('contactSearch', { q }),
          dispatch('conversationSearch', { q }),
          dispatch('messageSearch', { q }),
        ]),
    };
    try {
      await (searchActions[type] || searchActions.default)();
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.FULL_SEARCH_SET_UI_FLAG, {
        isFetching: false,
        isSearchCompleted: true,
      });
    }
  },
  async contactSearch({ commit }, { q }) {
    commit(types.CONTACT_SEARCH_SET, []);
    commit(types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.contacts({ q });
      commit(types.CONTACT_SEARCH_SET, data.payload.contacts);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async conversationSearch({ commit }, { q }) {
    commit(types.CONVERSATION_SEARCH_SET, []);
    commit(types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.conversations({ q });
      commit(types.CONVERSATION_SEARCH_SET, data.payload.conversations);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async messageSearch({ commit }, { q, page = 1 }) {
    commit(types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.messages({ q, page });
      commit(types.MESSAGE_SEARCH_SET, data.payload.messages);
      commit(types.MESSAGE_SEARCH_SET_META, data.payload.meta);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async clearSearchResults({ commit }) {
    commit(types.MESSAGE_SEARCH_SET, []);
    commit(types.MESSAGE_SEARCH_SET_META, {
      current_page: 1,
      total_count: 0,
      total_pages: 0,
    });
    commit(types.CONVERSATION_SEARCH_SET, []);
    commit(types.CONTACT_SEARCH_SET, []);
  },
};

export const mutations = {
  [types.SEARCH_CONVERSATIONS_SET](state, records) {
    state.records = records;
  },
  [types.CONTACT_SEARCH_SET](state, records) {
    state.contactRecords = records;
  },
  [types.CONVERSATION_SEARCH_SET](state, records) {
    state.conversationRecords = records;
  },
  [types.MESSAGE_SEARCH_SET](state, records) {
    state.messageRecords = records;
  },
  [types.MESSAGE_SEARCH_SET_META](state, meta) {
    state.messageMeta = {
      currentPage: meta.current_page,
      totalCount: meta.total_count,
      totalPages: meta.total_pages,
    };
  },
  [types.SEARCH_CONVERSATIONS_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags = { ...state.uiFlags, ...uiFlags };
  },
  [types.FULL_SEARCH_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags = { ...state.uiFlags, ...uiFlags };
  },
  [types.CONTACT_SEARCH_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags.contact = { ...state.uiFlags.contact, ...uiFlags };
  },
  [types.CONVERSATION_SEARCH_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags.conversation = { ...state.uiFlags.conversation, ...uiFlags };
  },
  [types.MESSAGE_SEARCH_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags.message = { ...state.uiFlags.message, ...uiFlags };
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  actions,
  mutations,
};
