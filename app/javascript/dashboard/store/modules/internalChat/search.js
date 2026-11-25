import InternalChatChannelsAPI from 'dashboard/api/internalChatChannels';

const initialState = () => ({
  query: '',
  channels: [],
  dms: [],
  messages: [],
  searchLimited: false,
  uiFlags: {
    isFetching: false,
    hasMoreMessages: false,
    currentPage: 1,
  },
});

const state = initialState();

const getters = {
  getQuery: _state => _state.query,
  getChannels: _state => _state.channels,
  getDMs: _state => _state.dms,
  getMessages: _state => _state.messages,
  getUIFlags: _state => _state.uiFlags,
  isSearchLimited: _state => _state.searchLimited,
};

const actions = {
  async search({ commit }, { query, page = 1 }) {
    commit('SET_QUERY', query);
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const { data } = await InternalChatChannelsAPI.search({
        q: query,
        page,
      });
      if (page === 1) {
        commit('SET_RESULTS', data);
      } else {
        commit('APPEND_MESSAGES', data.messages || []);
      }
      commit('SET_UI_FLAG', {
        hasMoreMessages: data.meta?.messages_has_more || false,
        currentPage: page,
      });
    } catch {
      // silently handle
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },

  clearSearch({ commit }) {
    commit('CLEAR_RESULTS');
  },
};

const mutations = {
  RESET(_state) {
    Object.assign(_state, initialState());
  },
  SET_QUERY(_state, query) {
    _state.query = query;
  },
  SET_RESULTS(_state, data) {
    _state.channels = data.channels || [];
    _state.dms = data.dms || [];
    _state.messages = data.messages || [];
    _state.searchLimited = data.meta?.search_limited || false;
  },
  APPEND_MESSAGES(_state, messages) {
    _state.messages = [..._state.messages, ...messages];
  },
  CLEAR_RESULTS(_state) {
    _state.query = '';
    _state.channels = [];
    _state.dms = [];
    _state.messages = [];
    _state.searchLimited = false;
  },
  SET_UI_FLAG(_state, flags) {
    _state.uiFlags = { ..._state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
