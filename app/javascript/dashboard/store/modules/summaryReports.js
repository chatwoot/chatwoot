import SummaryReportsAPI from '../../api/summaryReports';
import Vue from 'vue';

export const state = {
  teamSummaryReports: [],
  agentSummaryReports: [],
  inboxSummaryReports: [],
  uiFlags: {},
};

export const getters = {
  getAgentSummaryReports(_state) {
    return _state.agentSummaryReports;
  },
  getTeamSummaryReports(_state) {
    return _state.teamSummaryReports;
  },
  getInboxSummaryReports(_state) {
    return _state.inboxSummaryReports;
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
  async fetchAgentSummaryReports({ commit }, params) {
    try {
      const response = await SummaryReportsAPI.getAgentReports(params);
      commit('setAgentSummaryReport', response.data);
    } catch (error) {
      // Ignore error
    }
  },
  async fetchInboxSummaryReports({ commit }, params) {
    try {
      const response = await SummaryReportsAPI.getInboxReports(params);
      commit('setInboxSummaryReport', response.data);
    } catch (error) {
      // Ignore error
    }
  },
};

export const mutations = {
  setTeamSummaryReport(_state, data) {
    Vue.set(_state, 'teamSummaryReports', data);
  },
  setAgentSummaryReport(_state, data) {
    Vue.set(_state, 'agentSummaryReports', data);
  },
  setInboxSummaryReport(_state, data) {
    Vue.set(_state, 'inboxSummaryReports', data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
