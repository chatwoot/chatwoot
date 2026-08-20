import SearchAPI from '../../api/search';
import types from '../mutation-types';

const PER_PAGE = 15;

// Paginated search responses can overlap across pages (new records shift
// offsets between fetches), so drop records that are already in the list.
const appendUniqueRecords = (existingRecords, newRecords) => {
  const existingIds = new Set(existingRecords.map(record => record.id));
  return [
    ...existingRecords,
    ...newRecords.filter(record => !existingIds.has(record.id)),
  ];
};
export const initialState = {
  records: [],
  contactRecords: [],
  conversationRecords: [],
  messageRecords: [],
  articleRecords: [],
  uiFlags: {
    isFetching: false,
    isSearchCompleted: false,
    contact: { isFetching: false },
    conversation: { isFetching: false },
    message: { isFetching: false },
    article: { isFetching: false },
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
  getArticleRecords(state) {
    return state.articleRecords;
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
  async fullSearch({ commit, dispatch }, payload) {
    const { q, ...filters } = payload;
    if (!q && !Object.keys(filters).length) {
      return;
    }
    commit(types.FULL_SEARCH_SET_UI_FLAG, {
      isFetching: true,
      isSearchCompleted: false,
    });
    try {
      await Promise.all([
        dispatch('contactSearch', { q, ...filters }),
        dispatch('conversationSearch', { q, ...filters }),
        dispatch('messageSearch', { q, ...filters }),
        dispatch('articleSearch', { q, ...filters }),
      ]);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.FULL_SEARCH_SET_UI_FLAG, {
        isFetching: false,
        isSearchCompleted: true,
      });
    }
  },
  async contactSearch({ commit }, payload) {
    const { page = 1, ...searchParams } = payload;
    commit(types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.contacts({ ...searchParams, page });
      commit(types.CONTACT_SEARCH_SET, data.payload.contacts);
      // hasMore uses the raw page size: the records above may shrink on
      // dedupe, so stored counts cannot signal whether more pages exist
      commit(types.CONTACT_SEARCH_SET_UI_FLAG, {
        hasMore: data.payload.contacts.length === PER_PAGE,
      });
      return true;
    } catch (error) {
      // Failure is reported so callers can roll back their page counter
      return false;
    } finally {
      commit(types.CONTACT_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async conversationSearch({ commit }, payload) {
    const { page = 1, ...searchParams } = payload;
    commit(types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.conversations({ ...searchParams, page });
      commit(types.CONVERSATION_SEARCH_SET, data.payload.conversations);
      commit(types.CONVERSATION_SEARCH_SET_UI_FLAG, {
        hasMore: data.payload.conversations.length === PER_PAGE,
      });
      return true;
    } catch (error) {
      // Failure is reported so callers can roll back their page counter
      return false;
    } finally {
      commit(types.CONVERSATION_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async messageSearch({ commit }, payload) {
    const { page = 1, ...searchParams } = payload;
    commit(types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.messages({ ...searchParams, page });
      commit(types.MESSAGE_SEARCH_SET, data.payload.messages);
      commit(types.MESSAGE_SEARCH_SET_UI_FLAG, {
        hasMore: data.payload.messages.length === PER_PAGE,
      });
      return true;
    } catch (error) {
      // Failure is reported so callers can roll back their page counter
      return false;
    } finally {
      commit(types.MESSAGE_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async articleSearch({ commit }, payload) {
    const { page = 1, ...searchParams } = payload;
    commit(types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.articles({ ...searchParams, page });
      commit(types.ARTICLE_SEARCH_SET, data.payload.articles);
      commit(types.ARTICLE_SEARCH_SET_UI_FLAG, {
        hasMore: data.payload.articles.length === PER_PAGE,
      });
      return true;
    } catch (error) {
      // Failure is reported so callers can roll back their page counter
      return false;
    } finally {
      commit(types.ARTICLE_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async clearSearchResults({ commit }) {
    commit(types.CLEAR_SEARCH_RESULTS);
  },
};

export const mutations = {
  [types.SEARCH_CONVERSATIONS_SET](state, records) {
    state.records = records;
  },
  [types.CONTACT_SEARCH_SET](state, records) {
    state.contactRecords = appendUniqueRecords(state.contactRecords, records);
  },
  [types.CONVERSATION_SEARCH_SET](state, records) {
    state.conversationRecords = appendUniqueRecords(
      state.conversationRecords,
      records
    );
  },
  [types.MESSAGE_SEARCH_SET](state, records) {
    state.messageRecords = appendUniqueRecords(state.messageRecords, records);
  },
  [types.ARTICLE_SEARCH_SET](state, records) {
    state.articleRecords = appendUniqueRecords(state.articleRecords, records);
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
  [types.ARTICLE_SEARCH_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags.article = { ...state.uiFlags.article, ...uiFlags };
  },
  [types.CLEAR_SEARCH_RESULTS](state) {
    state.contactRecords = [];
    state.conversationRecords = [];
    state.messageRecords = [];
    state.articleRecords = [];
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  actions,
  mutations,
};
