import SummaryReportsAPI from 'dashboard/api/summaryReports';
import camelcaseKeys from 'camelcase-keys';

const typeMap = {
  inbox: {
    flagKey: 'isFetchingInboxSummaryReports',
    apiMethod: 'getInboxReports',
    mutationKey: 'setInboxSummaryReport',
  },
  agent: {
    flagKey: 'isFetchingAgentSummaryReports',
    apiMethod: 'getAgentReports',
    mutationKey: 'setAgentSummaryReport',
  },
  team: {
    flagKey: 'isFetchingTeamSummaryReports',
    apiMethod: 'getTeamReports',
    mutationKey: 'setTeamSummaryReport',
  },
};

async function fetchSummaryReports(type, params, { commit }) {
  const config = typeMap[type];
  if (!config) return;

  try {
    commit('setUIFlags', { [config.flagKey]: true });
    const response = await SummaryReportsAPI[config.apiMethod](params);
    commit(config.mutationKey, camelcaseKeys(response.data, { deep: true }));
  } catch (error) {
    // Ignore error
  } finally {
    commit('setUIFlags', { [config.flagKey]: false });
  }
}

export const initialState = {
  inboxSummaryReports: [],
  agentSummaryReports: [],
  teamSummaryReports: [],
  uiFlags: {
    isFetchingInboxSummaryReports: false,
    isFetchingAgentSummaryReports: false,
    isFetchingTeamSummaryReports: false,
  },
};

export const getters = {
  getInboxSummaryReports(state) {
    return state.inboxSummaryReports;
  },
  getAgentSummaryReports(state) {
    return state.agentSummaryReports;
  },
  getTeamSummaryReports(state) {
    return state.teamSummaryReports;
  },
  getUIFlags(state) {
    return state.uiFlags;
  },
};

export const actions = {
  fetchInboxSummaryReports({ commit }, params) {
    return fetchSummaryReports('inbox', params, { commit });
  },

  fetchAgentSummaryReports({ commit }, params) {
    return fetchSummaryReports('agent', params, { commit });
  },

  fetchTeamSummaryReports({ commit }, params) {
    return fetchSummaryReports('team', params, { commit });
  },
};

export const mutations = {
  setInboxSummaryReport(state, data) {
    state.inboxSummaryReports = data;
  },
  setAgentSummaryReport(state, data) {
    state.agentSummaryReports = data;
  },
  setTeamSummaryReport(state, data) {
    state.teamSummaryReports = data;
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
