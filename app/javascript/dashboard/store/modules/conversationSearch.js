import SearchAPI from '../../api/search';
import types from '../mutation-types';
export const initialState = {
  records: [],
  fullSearchRecords: {},
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getConversations(state) {
    return state.records;
  },
  getFullSearchRecords(state) {
    return state.fullSearchRecords;
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
  async fullSearch({ commit }, { q }) {
    commit(types.FULL_SEARCH_SET, []);
    if (!q) {
      return;
    }
    commit(types.FULL_SEARCH_SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await SearchAPI.get({ q });
      commit(types.FULL_SEARCH_SET, data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.FULL_SEARCH_SET_UI_FLAG, { isFetching: false });
    }
  },
  async clearSearchResults({ commit }) {
    commit(types.FULL_SEARCH_SET, {});
  },
};

export const mutations = {
  [types.SEARCH_CONVERSATIONS_SET](state, records) {
    state.records = records;
  },
  [types.FULL_SEARCH_SET](state, records) {
    state.fullSearchRecords = records;
  },
  [types.SEARCH_CONVERSATIONS_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags = { ...state.uiFlags, ...uiFlags };
  },
  [types.FULL_SEARCH_SET_UI_FLAG](state, uiFlags) {
    state.uiFlags = { ...state.uiFlags, ...uiFlags };
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  actions,
  mutations,
};
