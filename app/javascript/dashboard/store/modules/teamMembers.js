import Vue from 'vue';
import TeamsAPI from '../../api/teams';

const SET_TEAM_MEMBERS_UI_FLAG = 'SET_TEAM_MEMBERS_UI_FLAG';
const ADD_AGENTS_TO_TEAM = 'ADD_AGENTS_TO_TEAM';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getTeamMembers: $state => id => {
    const members = $state.records[id];
    return members || {};
  },
};

const actions = {
  get: async ({ commit }, { teamId }) => {
    commit(SET_TEAM_MEMBERS_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TeamsAPI.getAgents({ teamId });
      commit(ADD_AGENTS_TO_TEAM, { data, teamId });
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isFetching: false });
    }
  },
  update: async ({ commit }, { agentsList, teamId }) => {
    commit(SET_TEAM_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TeamsAPI.updateAgents({ agentsList, teamId });
      commit(ADD_AGENTS_TO_TEAM, response);
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },
  create: async ({ commit }, { agentsList, teamId }) => {
    commit(SET_TEAM_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TeamsAPI.addAgents({ agentsList, teamId });
      commit(ADD_AGENTS_TO_TEAM, response);
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isCreating: false });
    } catch (error) {
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isCreating: false });
    }
  },
};

const mutations = {
  [SET_TEAM_MEMBERS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [ADD_AGENTS_TO_TEAM]($state, { data, teamId }) {
    Vue.set($state.records, teamId, data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
