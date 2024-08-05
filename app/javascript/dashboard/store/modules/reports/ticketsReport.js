import * as types from '../../mutation-types';
import ReportsAPI from '../../../api/reports';

export const state = {
  records: [],
  summary: {
    total: 0,
    resolved: 0,
    unresolved: 0,
  },
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getTicketsAgentsReport($state) {
    return $state.records;
  },
  getTicketsSummary($state) {
    return $state.summary;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  getAll: async ({ commit }, { from, to, businessHours }) => {
    commit(types.default.SET_TICKETS_UI_FLAG_REPORT, { isFetching: true });
    try {
      const response = await ReportsAPI.getTicketsReport({
        from,
        to,
        businessHours,
      });
      commit(types.default.SET_TICKETS_UI_FLAG_REPORT, { isFetching: false });
      commit(types.default.SET_TICKETS_REPORT, response.data);
    } catch (error) {
      commit(types.default.SET_TICKETS_UI_FLAG_REPORT, { isFetching: false });
    }
  },
  getSummary: async ({ commit }, { from, to }) => {
    commit(types.default.SET_TICKETS_UI_FLAG_REPORT, { isFetching: true });
    try {
      const response = await ReportsAPI.getTicketsSummaryReport({ from, to });
      commit(types.default.SET_TICKETS_UI_FLAG_REPORT, { isFetching: false });
      commit(types.default.SET_TICKETS_REPORT_METRIC, response.data);
    } catch (error) {
      commit(types.default.SET_TICKETS_UI_FLAG_REPORT, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.default.SET_TICKETS_UI_FLAG_REPORT]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_TICKETS_REPORT]($state, data) {
    $state.records = data;
  },
  [types.default.SET_TICKETS_REPORT_METRIC]($state, data) {
    $state.summary = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
