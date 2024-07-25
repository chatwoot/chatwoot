import * as types from '../../mutation-types';
import ReportsAPI from '../../../api/reports';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getInvoices($state) {
    return $state.records;
  },

  getInvoice: $state => invoiceId => {
    const [invoice] = $state.records.filter(
      record => record.id === Number(invoiceId)
    );
    return invoice || {};
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_INVOICES_UI_FLAG, { isFetching: true });
    try {
      const response = await ReportsAPI.getInvoicesReport(true);
      commit(types.default.SET_INVOICES_UI_FLAG, { isFetching: false });
      commit(types.default.SET_INBOXES, response.data.payload);
    } catch (error) {
      commit(types.default.SET_INVOICES_UI_FLAG, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.default.SET_INVOICES_UI_FLAG]($state, uiFlag) {
    $state.uiFlags = { ...$state.uiFlags, ...uiFlag };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
