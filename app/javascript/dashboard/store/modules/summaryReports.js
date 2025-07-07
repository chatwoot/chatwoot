import SummaryReportsAPI from '../../api/summaryReports';
import CustomReportsAPI from '../../api/customReports';
import Vue from 'vue';

export const state = {
  teamSummaryReports: [],
  agentSummaryReports: [],
  inboxSummaryReports: [],
  customAgentOverviewReports: [],
  customAgentConversationStatesReports: [],
  customLabelConversationStatesReports: [],
  customAgentCallOverviewReports: [],
  customAgentInboundCallOverviewReports: [],
  customBotAnalyticsSalesOverviewReports: [],
  customLiveChatSalesOverviewReports: [],
  customBotAnalyticsSupportOverviewReports: [],
  customLiveChatSupportOverviewReports: [],
  currency: null,
  liveChatCurrency: null,
  uiFlags: {
    isBotAnalyticsSalesOverviewReportsLoading: false,
    isBotAnalyticsSupportOverviewReportsLoading: false,
    isAgentOverviewReportsLoading: false,
    isAgentConversationStatesReportsLoading: false,
    isAgentCallOverviewReportsLoading: false,
    isAgentInboundCallOverviewReportsLoading: false,
    isLabelConversationStatesReportsLoading: false,
    isLiveChatSalesOverviewReportsLoading: false,
    isLiveChatSupportOverviewReportsLoading: false,
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
  getCustomLabelConversationStatesReports(_state) {
    return _state.customLabelConversationStatesReports;
  },
  getCustomAgentCallOverviewReports(_state) {
    return _state.customAgentCallOverviewReports;
  },
  getCustomAgentInboundCallOverviewReports(_state) {
    return _state.customAgentInboundCallOverviewReports;
  },
  getCustomBotAnalyticsSalesOverviewReports(_state) {
    return _state.customBotAnalyticsSalesOverviewReports;
  },
  getCustomLiveChatSalesOverviewReports(_state) {
    return _state.customLiveChatSalesOverviewReports;
  },
  getCustomBotAnalyticsSupportOverviewReports(_state) {
    return _state.customBotAnalyticsSupportOverviewReports;
  },
  getCustomLiveChatSupportOverviewReports(_state) {
    return _state.customLiveChatSupportOverviewReports;
  },
  getUiFlags(_state) {
    return _state.uiFlags;
  },
  getCurrency(_state) {
    return _state.currency;
  },
  getLiveChatCurrency(_state) {
    return _state.liveChatCurrency;
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
  async fetchCustomLiveChatSalesOverviewReports({ commit }, params) {
    commit('toggleLiveChatSalesOverviewReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomLiveChatSalesOverviewReports(params);
      commit('setCustomLiveChatSalesOverviewReport', response.data);
      commit('toggleLiveChatSalesOverviewReportsLoading', false);
    } catch (error) {
      commit('toggleLiveChatSalesOverviewReportsLoading', false);
    }
  },
  async fetchCustomLiveChatSupportOverviewReports({ commit }, params) {
    commit('toggleLiveChatSupportOverviewReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomLiveChatSupportOverviewReports(params);
      commit('setCustomLiveChatSupportOverviewReport', response.data);
      commit('toggleLiveChatSupportOverviewReportsLoading', false);
    } catch (error) {
      commit('toggleLiveChatSupportOverviewReportsLoading', false);
    }
  },
  async fetchCurrency({ commit }) {
    try {
      const response = await CustomReportsAPI.getCurrency();
      commit('setCurrency', response.data.currency);
    } catch (error) {
      // Ignore error
    }
  },
  async fetchLiveChatCurrency({ commit }) {
    try {
      const response = await CustomReportsAPI.getLiveChatCurrency();
      commit('setLiveChatCurrency', response.data.currency);
    } catch (error) {
      // Ignore error
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
  async fetchCustomAgentInboundCallOverviewReports({ commit }, params) {
    commit('toggleAgentInboundCallOverviewReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomAgentInboundCallOverviewReports(params);
      commit('setCustomAgentInboundCallOverviewReport', response.data);
      commit('toggleAgentInboundCallOverviewReportsLoading', false);
    } catch (error) {
      commit('toggleAgentInboundCallOverviewReportsLoading', false);
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
  async fetchCustomLabelConversationStatesReports({ commit }, params) {
    commit('toggleLabelConversationStatesReportsLoading', true);
    try {
      const response =
        await CustomReportsAPI.getCustomLabelConversationStatesReports(params);
      commit('setCustomLabelConversationStatesReport', response.data);
      commit('toggleLabelConversationStatesReportsLoading', false);
    } catch (error) {
      commit('toggleLabelConversationStatesReportsLoading', false);
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
  setCustomLabelConversationStatesReport(_state, data) {
    Vue.set(_state, 'customLabelConversationStatesReports', data);
  },
  setCustomAgentCallOverviewReport(_state, data) {
    Vue.set(_state, 'customAgentCallOverviewReports', data);
  },
  setCustomAgentInboundCallOverviewReport(_state, data) {
    Vue.set(_state, 'customAgentInboundCallOverviewReports', data);
  },
  setCustomAgentOverviewReport(_state, data) {
    Vue.set(_state, 'customAgentOverviewReports', data);
  },
  setCustomBotAnalyticsSalesOverviewReport(_state, data) {
    Vue.set(_state, 'customBotAnalyticsSalesOverviewReports', data);
  },
  setCustomLiveChatSalesOverviewReport(_state, data) {
    Vue.set(_state, 'customLiveChatSalesOverviewReports', data);
  },
  setCustomBotAnalyticsSupportOverviewReport(_state, data) {
    Vue.set(_state, 'customBotAnalyticsSupportOverviewReports', data);
  },
  setCustomLiveChatSupportOverviewReport(_state, data) {
    Vue.set(_state, 'customLiveChatSupportOverviewReports', data);
  },
  setCurrency(_state, data) {
    Vue.set(_state, 'currency', data);
  },
  setLiveChatCurrency(_state, data) {
    Vue.set(_state, 'liveChatCurrency', data);
  },
  toggleBotAnalyticsSalesOverviewReportsLoading(_state, flag) {
    Vue.set(_state.uiFlags, 'isBotAnalyticsSalesOverviewReportsLoading', flag);
  },
  toggleLiveChatSalesOverviewReportsLoading(_state, flag) {
    Vue.set(_state.uiFlags, 'isLiveChatSalesOverviewReportsLoading', flag);
  },
  toggleBotAnalyticsSupportOverviewReportsLoading(_state, flag) {
    Vue.set(
      _state.uiFlags,
      'isBotAnalyticsSupportOverviewReportsLoading',
      flag
    );
  },
  toggleLiveChatSupportOverviewReportsLoading(_state, flag) {
    Vue.set(_state.uiFlags, 'isLiveChatSupportOverviewReportsLoading', flag);
  },
  toggleAgentOverviewReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isAgentOverviewReportsLoading', flag);
  },
  toggleAgentConversationStatesReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isAgentConversationStatesReportsLoading', flag);
  },
  toggleLabelConversationStatesReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isLabelConversationStatesReportsLoading', flag);
  },
  toggleAgentCallOverviewReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isAgentCallOverviewReportsLoading', flag);
  },
  toggleAgentInboundCallOverviewReportsLoading(_state, flag) {
    Vue.set(_state, 'uiFlags.isAgentInboundCallOverviewReportsLoading', flag);
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
