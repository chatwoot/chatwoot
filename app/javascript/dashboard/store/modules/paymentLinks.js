import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import PaymentLinksAPI from '../../api/paymentLinks';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import camelcaseKeys from 'camelcase-keys';

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
    amountMin: null,
    amountMax: null,
  },
  appliedFilters: [],
};

const getters = {
  getPaymentLinks(_state) {
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
  getAppliedPaymentLinkFilters(_state) {
    return _state.appliedFilters;
  },
  getAppliedPaymentLinkFiltersV4(_state) {
    return _state.appliedFilters.map(camelcaseKeys);
  },
};

const actions = {
  async fetch(
    { commit, rootGetters, state: storeState },
    { page, filters, sort = '', order = '' } = {}
  ) {
    commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      const filterParams = filters || storeState.filters;
      const response = await PaymentLinksAPI.get(
        accountId,
        page,
        filterParams,
        sort,
        order
      );
      const { payload: paymentLinks = [], meta = {} } = response.data;
      const { count: totalEntries, current_page: currentPage } = meta;

      commit(types.default.SET_PAYMENT_LINKS, paymentLinks);
      commit(types.default.SET_PAYMENT_LINKS_META, {
        totalEntries,
        perPage: 15,
        currentPage: Number(currentPage),
      });
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: false });
      return paymentLinks;
    } catch (error) {
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: false });
      return throwErrorMessage(error);
    }
  },
  async search(
    { commit, rootGetters },
    { page, search, sort = '', order = '' }
  ) {
    commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      const response = await PaymentLinksAPI.search(
        accountId,
        search,
        page,
        sort,
        order
      );
      const { payload: paymentLinks = [], meta = {} } = response.data;
      const { count: totalEntries, current_page: currentPage } = meta;

      commit(types.default.SET_PAYMENT_LINKS, paymentLinks);
      commit(types.default.SET_PAYMENT_LINKS_META, {
        totalEntries,
        perPage: 15,
        currentPage: Number(currentPage),
      });
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: false });
      return paymentLinks;
    } catch (error) {
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: false });
      return throwErrorMessage(error);
    }
  },
  async filter(
    { commit, rootGetters },
    { page, queryPayload, sort = '', order = '' }
  ) {
    commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      const response = await PaymentLinksAPI.filter(
        accountId,
        queryPayload,
        page,
        sort,
        order
      );
      const { payload: paymentLinks = [], meta = {} } = response.data;
      const { count: totalEntries, current_page: currentPage } = meta;

      commit(types.default.SET_PAYMENT_LINKS, paymentLinks);
      commit(types.default.SET_PAYMENT_LINKS_META, {
        totalEntries,
        perPage: 15,
        currentPage: Number(currentPage),
      });
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: false });
      return paymentLinks;
    } catch (error) {
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { fetchingList: false });
      return throwErrorMessage(error);
    }
  },
  async export({ commit, rootGetters }) {
    commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { isExporting: true });
    try {
      const accountId = rootGetters.getCurrentAccountId;
      await PaymentLinksAPI.exportPaymentLinks(accountId);
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { isExporting: false });
    } catch (error) {
      commit(types.default.SET_PAYMENT_LINKS_UI_FLAG, { isExporting: false });
      if (error.response?.data?.message) {
        throw new Error(error.response.data.message);
      } else {
        throw new Error(error);
      }
    }
  },
  setPaymentLinkFilters({ commit }, data) {
    commit(types.default.SET_PAYMENT_LINKS_FILTERS, data);
  },
  clearPaymentLinkFilters({ commit }) {
    commit(types.default.CLEAR_PAYMENT_LINKS_FILTERS);
  },
  setFilters({ commit, dispatch }, filters) {
    commit(types.default.SET_PAYMENT_LINKS_FILTERS, filters);
    dispatch('fetch', { page: 1 });
  },
  clearFilters({ commit, dispatch }) {
    commit(types.default.CLEAR_PAYMENT_LINKS_FILTERS);
    dispatch('fetch', { page: 1 });
  },
};

const mutations = {
  [types.default.SET_PAYMENT_LINKS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.default.SET_PAYMENT_LINKS]: MutationHelpers.set,
  [types.default.SET_PAYMENT_LINKS_META](_state, data) {
    _state.meta = {
      ..._state.meta,
      ...data,
    };
  },
  [types.default.SET_PAYMENT_LINKS_FILTERS](_state, filters) {
    if (Array.isArray(filters)) {
      _state.appliedFilters = filters;
    } else {
      _state.filters = {
        ..._state.filters,
        ...filters,
      };
    }
  },
  [types.default.CLEAR_PAYMENT_LINKS_FILTERS](_state) {
    _state.filters = {
      status: 'all',
      dateRange: 'all',
      dateFrom: null,
      dateTo: null,
      search: '',
      amountMin: null,
      amountMax: null,
    };
    _state.appliedFilters = [];
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
