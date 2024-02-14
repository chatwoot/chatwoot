import SummaryReportsAPI from '../../api/summaryReports';

export const state = {
  teamSummaryReports: [],
  agentSummaryReports: [],
  uiFlags: {},
};

export const getters = {
  getAgentSummaryReport(_state) {
    return _state.agentSummaryReports;
  },
  getTeamSummaryReports(_state) {
    return _state.teamSummaryReports;
  },
};

export const actions = {
  async fetchTeamSummaryReports({ commit }, params) {
    try {
      const response = await SummaryReportsAPI.getTeamReports(params);
      commit('setTeamSummaryReport', response.data);
    } catch (error) {
      // Ignore error
    }
  },
  async getAgentSummaryReports({ commit }, params) {
    try {
      const response = await SummaryReportsAPI.getAgentReports(params);
      commit('setAgentSummayReport', response.data);
    } catch (error) {
      // Ignore error
    }
  },
};

export const mutations = {
  setTeamSummaryReport(_state, data) {
    _state.teamSummaryReports = data;
  },
  setAgentSummaryReport(_state, data) {
    _state.agentSummaryReports = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
