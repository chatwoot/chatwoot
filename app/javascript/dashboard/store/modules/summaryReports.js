import SummaryReportsAPI from 'dashboard/api/summaryReports';
import camelcaseKeys from 'camelcase-keys';

export const initialState = {
  inboxSummaryReports: [],
  uiFlags: {
    isFetchingInboxSummaryReports: false,
  },
};

export const getters = {
  getInboxSummaryReports(state) {
    return state.inboxSummaryReports;
  },
  getUIFlags(state) {
    return state.uiFlags;
  },
};

export const actions = {
  async fetchInboxSummaryReports({ commit }, params) {
    try {
      commit('setUIFlags', { isFetchingInboxSummaryReports: true });
      const response = await SummaryReportsAPI.getInboxReports(params);
      commit(
        'setInboxSummaryReport',
        camelcaseKeys(response.data, { deep: true })
      );
    } catch (error) {
      // Ignore error
    } finally {
      commit('setUIFlags', { isFetchingInboxSummaryReports: false });
    }
  },
};

export const mutations = {
  setInboxSummaryReport(state, data) {
    state.inboxSummaryReports = data;
  },
  setUIFlags(state, uiFlag) {
    state.uiFlags = { ...state.uiFlags, ...uiFlag };
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  actions,
  mutations,
};
