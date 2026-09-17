import SearchAPI from '../../api/search';
import types from '../mutation-types';

import {
  SEARCH_ENTITIES,
  RESULTS_PER_PAGE,
  PREVIEW_PER_PAGE,
} from 'dashboard/modules/search/constants';

const entityName = type => type.slice(0, -1);
const recordKey = type => `${entityName(type)}Records`;

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
  searchId: 0,
  previews: {},
  pages: {},
  totals: {},
  countBackend: null,
  messageBackend: null,
  contactRecords: [],
  conversationRecords: [],
  messageRecords: [],
  articleRecords: [],
  uiFlags: {
    isFetching: false,
    isFetchingCounts: false,
    hasCountError: false,
    contact: { isFetching: false },
    conversation: { isFetching: false },
    message: { isFetching: false },
    article: { isFetching: false },
  },
};

export const getters = {
  getSearchState(state) {
    return state;
  },
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
  ...Object.fromEntries(
    SEARCH_ENTITIES.map(type => [
      `${entityName(type)}Search`,
      async ({ commit, state }, { signal, ...payload }) => {
        const searchId = state.searchId;
        const current = () => !signal?.aborted && state.searchId === searchId;
        const flag =
          types[`${entityName(type).toUpperCase()}_SEARCH_SET_UI_FLAG`];
        const { page = 1, perPage = RESULTS_PER_PAGE } = payload;
        commit(flag, { isFetching: true, hasError: false });
        try {
          const { data } = await SearchAPI[type](
            { ...payload, page },
            { signal }
          );
          if (!current()) return false;
          commit(types.SEARCH_RESULTS_RECEIVED, {
            type,
            records: data.payload[type],
            page,
            perPage,
            backend: data.meta?.message_backend,
          });
          commit(flag, { hasMore: data.payload[type].length === perPage });
          return true;
        } catch (error) {
          if (current()) commit(flag, { hasError: true });
          return false;
        } finally {
          if (current()) commit(flag, { isFetching: false });
        }
      },
    ])
  ),
  async fetchCounts({ commit, state }, { signal, ...payload }) {
    const searchId = state.searchId;
    const current = () => !signal?.aborted && state.searchId === searchId;
    commit(types.FULL_SEARCH_SET_UI_FLAG, {
      isFetchingCounts: true,
      hasCountError: false,
    });
    try {
      const { data } = await SearchAPI.counts(payload, { signal });
      if (current()) commit(types.SEARCH_COUNTS_RECEIVED, data);
    } catch (error) {
      if (current())
        commit(types.FULL_SEARCH_SET_UI_FLAG, { hasCountError: true });
    } finally {
      if (current())
        commit(types.FULL_SEARCH_SET_UI_FLAG, { isFetchingCounts: false });
    }
  },
  cancelResultRequests({ commit }) {
    SEARCH_ENTITIES.forEach(type => {
      commit(types[`${entityName(type).toUpperCase()}_SEARCH_SET_UI_FLAG`], {
        isFetching: false,
      });
    });
  },
  async clearSearchResults({ commit }) {
    commit(types.CLEAR_SEARCH_RESULTS);
  },
};

export const mutations = {
  [types.SEARCH_RESULTS_RECEIVED](
    state,
    { type, records, page, perPage, backend }
  ) {
    if (perPage === PREVIEW_PER_PAGE) {
      state.previews[type] = records;
    } else {
      state[recordKey(type)] =
        page === 1
          ? records
          : appendUniqueRecords(state[recordKey(type)], records);
      state.pages[type] = page;
    }
    if (type === 'messages') state.messageBackend = backend;
  },
  [types.SEARCH_COUNTS_RECEIVED](state, { payload, meta }) {
    state.totals = payload.counts;
    state.countBackend = meta?.message_backend;
  },

  [types.SEARCH_CONVERSATIONS_SET](state, records) {
    state.records = records;
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
    state.searchId = (state.searchId || 0) + 1;
    state.previews = {};
    state.pages = {};
    state.totals = {};
    state.countBackend = null;
    state.messageBackend = null;
    state.uiFlags = {
      isFetching: false,
      isFetchingCounts: false,
      hasCountError: false,
      ...Object.fromEntries(
        SEARCH_ENTITIES.map(type => [
          entityName(type),
          { isFetching: false, hasError: false, hasMore: false },
        ])
      ),
    };
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
