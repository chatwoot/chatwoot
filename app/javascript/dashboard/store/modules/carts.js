import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import CartsAPI from '../../api/carts';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const state = {
  records: [],
  meta: {
    currentPage: 1,
    perPage: 15,
    totalEntries: 0,
  },
  uiFlags: {
    fetchingList: false,
  },
  filters: {
    status: 'all',
    dateRange: 'all',
    dateFrom: null,
    dateTo: null,
    search: '',
  },
};

const getters = {
  getCarts(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getMeta(_state) {
    return _state.meta;
  },
  getFilters(_state) {
    return _state.filters;
  },
};

const actions = {
  async fetch(
    { commit, rootGetters, state: storeState },
    { page, filters, sort = '', order = '' } = {}
  ) {
    commit(types.default.SET_CARTS_UI_FLAG, { fetchingList: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      const filterParams = filters || storeState.filters;
      const response = await CartsAPI.get(
        accountId,
        page,
        filterParams,
        sort,
        order
      );
      const { payload: carts = [], meta = {} } = response.data;
      const { count: totalEntries, current_page: currentPage } = meta;

      commit(types.default.SET_CARTS, carts);
      commit(types.default.SET_CARTS_META, {
        totalEntries,
        perPage: 15,
        currentPage: Number(currentPage),
      });
      commit(types.default.SET_CARTS_UI_FLAG, { fetchingList: false });
      return carts;
    } catch (error) {
      commit(types.default.SET_CARTS_UI_FLAG, { fetchingList: false });
      return throwErrorMessage(error);
    }
  },
  async search(
    { commit, rootGetters },
    { page, search, sort = '', order = '' }
  ) {
    commit(types.default.SET_CARTS_UI_FLAG, { fetchingList: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      const response = await CartsAPI.search(
        accountId,
        search,
        page,
        sort,
        order
      );
      const { payload: carts = [], meta = {} } = response.data;
      const { count: totalEntries, current_page: currentPage } = meta;

      commit(types.default.SET_CARTS, carts);
      commit(types.default.SET_CARTS_META, {
        totalEntries,
        perPage: 15,
        currentPage: Number(currentPage),
      });
      commit(types.default.SET_CARTS_UI_FLAG, { fetchingList: false });
      return carts;
    } catch (error) {
      commit(types.default.SET_CARTS_UI_FLAG, { fetchingList: false });
      return throwErrorMessage(error);
    }
  },
  setFilters({ commit, dispatch }, filters) {
    commit(types.default.SET_CARTS_FILTERS, filters);
    dispatch('fetch', { page: 1 });
  },
  clearFilters({ commit, dispatch }) {
    commit(types.default.CLEAR_CARTS_FILTERS);
    dispatch('fetch', { page: 1 });
  },
};

const mutations = {
  [types.default.SET_CARTS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_CARTS]: MutationHelpers.set,
  [types.default.SET_CARTS_META](_state, data) {
    _state.meta = {
      ..._state.meta,
      ...data,
    };
  },
  [types.default.SET_CARTS_FILTERS](_state, filters) {
    _state.filters = {
      ..._state.filters,
      ...filters,
    };
  },
  [types.default.CLEAR_CARTS_FILTERS](_state) {
    _state.filters = {
      status: 'all',
      dateRange: 'all',
      dateFrom: null,
      dateTo: null,
      search: '',
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
