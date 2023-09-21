import Vue from 'vue';
import TeamsAPI from '../../api/teams';

export const SET_TEAM_MEMBERS_UI_FLAG = 'SET_TEAM_MEMBERS_UI_FLAG';
export const ADD_AGENTS_TO_TEAM = 'ADD_AGENTS_TO_TEAM';

export const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getTeamMembers: $state => id => {
    return $state.records[id] || [];
  },
};

export const actions = {
  get: async ({ commit }, { teamId }) => {
    commit(SET_TEAM_MEMBERS_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TeamsAPI.getAgents({ teamId });
      commit(ADD_AGENTS_TO_TEAM, { data, teamId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isFetching: false });
    }
  },
  create: async ({ commit }, { agentsList, teamId }) => {
    commit(SET_TEAM_MEMBERS_UI_FLAG, { isCreating: true });
    try {
      const { data } = await TeamsAPI.addAgents({ agentsList, teamId });
      commit(ADD_AGENTS_TO_TEAM, { teamId, data });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { agentsList, teamId }) => {
    commit(SET_TEAM_MEMBERS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TeamsAPI.updateAgents({
        agentsList,
        teamId,
      });
      commit(ADD_AGENTS_TO_TEAM, response);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TEAM_MEMBERS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
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
