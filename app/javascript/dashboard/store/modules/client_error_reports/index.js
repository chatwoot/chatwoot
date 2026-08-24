import ClientErrorReportsApi from '../../api/clientErrorReports';

const state = {
  reports: [],
  uiFlags: { isFetching: false },
};

export const getters = {
  getReports: s => s.reports,
  getUIFlags: s => s.uiFlags,
};

export const actions = {
  fetch: async ({ commit }, page = 1) => {
    commit('setUIFlags', { isFetching: true });
    try {
      const { data } = await ClientErrorReportsApi.getReports(page);
      return data;
    } finally {
      commit('setUIFlags', { isFetching: false });
    }
  },
};

export const mutations = {
  setReports($state, reports) {
    $state.reports = reports;
  },
  setUIFlags($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
