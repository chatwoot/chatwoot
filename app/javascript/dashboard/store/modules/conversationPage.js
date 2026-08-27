import * as types from '../mutation-types';

const state = {
  currentPage: {
    me: 0,
    unassigned: 0,
    all: 0,
    appliedFilters: 0,
  },
  loadedCount: {
    me: 0,
    unassigned: 0,
    all: 0,
    appliedFilters: 0,
  },
  hasEndReached: {
    me: false,
    unassigned: false,
    all: false,
  },
};

export const getters = {
  getHasEndReached: $state => filter => {
    return $state.hasEndReached[filter];
  },
  getCurrentPageFilter: $state => filter => {
    return $state.currentPage[filter];
  },
  getLoadedCountFilter: $state => filter => {
    return $state.loadedCount[filter];
  },
  getCurrentPage: $state => {
    return $state.currentPage;
  },
};

export const actions = {
  setCurrentPage({ commit }, pageData) {
    commit(types.default.SET_CURRENT_PAGE, pageData);
  },
  setEndReached({ commit }, { filter }) {
    commit(types.default.SET_CONVERSATION_END_REACHED, { filter });
  },
  reset({ commit }) {
    commit(types.default.CLEAR_CONVERSATION_PAGE);
  },
};

export const mutations = {
  [types.default.SET_CURRENT_PAGE]: (
    $state,
    { filter, page, loadedCount = 0 }
  ) => {
    $state.currentPage = {
      ...$state.currentPage,
      [filter]: page,
    };
    $state.loadedCount = {
      ...$state.loadedCount,
      [filter]:
        page === 1
          ? loadedCount
          : ($state.loadedCount[filter] || 0) + loadedCount,
    };
  },
  [types.default.SET_CONVERSATION_END_REACHED]: ($state, { filter }) => {
    $state.hasEndReached = {
      ...$state.hasEndReached,
      [filter]: true,
    };
  },
  [types.default.CLEAR_CONVERSATION_PAGE]: $state => {
    $state.currentPage = {
      me: 0,
      unassigned: 0,
      all: 0,
      appliedFilters: 0,
    };

    $state.hasEndReached = {
      me: false,
      unassigned: false,
      all: false,
      appliedFilters: false,
    };
    $state.loadedCount = {
      me: 0,
      unassigned: 0,
      all: 0,
      appliedFilters: 0,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
