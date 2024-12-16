import SummaryReportsAPI from '../../api/summaryReports';
import CustomReportsAPI from '../../api/customReports';
import Vue from 'vue';

export const state = {
  teamSummaryReports: [],
  agentSummaryReports: [],
  inboxSummaryReports: [],
  customAgentOverviewReports: [],
  customAgentConversationStatesReports: [],
  customAgentCallOverviewReports: [],
  customBotAnalyticsSalesOverviewReports: [],
  customBotAnalyticsSupportOverviewReports: [],
  uiFlags: {
    isBotAnalyticsSalesOverviewReportsLoading: false,
    isBotAnalyticsSupportOverviewReportsLoading: false,
    isAgentOverviewReportsLoading: false,
    isAgentConversationStatesReportsLoading: false,
    isAgentCallOverviewReportsLoading: false,
  },
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
  getCustomAgentOverviewReports(_state) {
    return _state.customAgentOverviewReports;
  },
  getCustomAgentConversationStatesReports(_state) {
    return _state.customAgentConversationStatesReports;
  },
  getCustomAgentCallOverviewReports(_state) {
    return _state.customAgentCallOverviewReports;
  },
  getCustomBotAnalyticsSalesOverviewReports(_state) {
    return _state.customBotAnalyticsSalesOverviewReports;
  },
  getCustomBotAnalyticsSupportOverviewReports(_state) {
    return _state.customBotAnalyticsSupportOverviewReports;
  },
  getUiFlags(_state) {
    return _state.uiFlags;
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
  async fetchCustomAgentOverviewReports({ commit }, params) {
    commit('toggleAgentOverviewReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomAgentOverviewReports(params);
      commit('setCustomAgentOverviewReport', response.data);
      commit('toggleAgentOverviewReportsLoading', false);
    } catch (error) {
      commit('toggleAgentOverviewReportsLoading', false);
    }
  },
  async fetchCustomBotAnalyticsSalesOverviewReports({ commit }, params) {
    commit('toggleBotAnalyticsSalesOverviewReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomBotAnalyticsSalesOverviewReports(
          params
        );
      commit('setCustomBotAnalyticsSalesOverviewReport', response.data);
      commit('toggleBotAnalyticsSalesOverviewReportsLoading', false);
    } catch (error) {
      commit('toggleBotAnalyticsSalesOverviewReportsLoading', false);
    }
  },
  async fetchCustomBotAnalyticsSupportOverviewReports({ commit }, params) {
    commit('toggleBotAnalyticsSupportOverviewReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomBotAnalyticsSupportOverviewReports(
          params
        );
      commit('setCustomBotAnalyticsSupportOverviewReport', response.data);
      commit('toggleBotAnalyticsSupportOverviewReportsLoading', false);
    } catch (error) {
      commit('toggleBotAnalyticsSupportOverviewReportsLoading', false);
    }
  },
  async fetchCustomAgentConversationStatesReports({ commit }, params) {
    commit('toggleAgentConversationStatesReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomAgentConversationStatesReports(params);
      commit('setCustomAgentConversationStatesReport', response.data);
      commit('toggleAgentConversationStatesReportsLoading', false);
    } catch (error) {
      commit('toggleAgentConversationStatesReportsLoading', false);
    }
  },
  async fetchCustomAgentCallOverviewReports({ commit }, params) {
    commit('toggleAgentCallOverviewReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomAgentCallOverviewReports(params);
      commit('setCustomAgentCallOverviewReport', response.data);
      commit('toggleAgentCallOverviewReportsLoading', false);
    } catch (error) {
      commit('toggleAgentCallOverviewReportsLoading', false);
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
  setCustomAgentConversationStatesReport(_state, data) {
    Vue.set(_state, 'customAgentConversationStatesReports', data);
  },
  setCustomAgentCallOverviewReport(_state, data) {
    Vue.set(_state, 'customAgentCallOverviewReports', data);
  },
  setCustomAgentOverviewReport(_state, data) {
    Vue.set(_state, 'customAgentOverviewReports', data);
  },
  setCustomBotAnalyticsSalesOverviewReport(_state, data) {
    Vue.set(_state, 'customBotAnalyticsSalesOverviewReports', data);
  },
  setCustomBotAnalyticsSupportOverviewReport(_state, data) {
    Vue.set(_state, 'customBotAnalyticsSupportOverviewReports', data);
  },
  toggleBotAnalyticsSalesOverviewReportsLoading(_state, flag) {
    Vue.set(_state.uiFlags, 'isBotAnalyticsSalesOverviewReportsLoading', flag);
  },
  toggleBotAnalyticsSupportOverviewReportsLoading(_state, flag) {
    Vue.set(
      _state.uiFlags,
      'isBotAnalyticsSupportOverviewReportsLoading',
      flag
    );
  },
  toggleAgentOverviewReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isAgentOverviewReportsLoading', flag);
  },
  toggleAgentConversationStatesReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isAgentConversationStatesReportsLoading', flag);
  },
  toggleAgentCallOverviewReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isAgentCallOverviewReportsLoading', flag);
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
