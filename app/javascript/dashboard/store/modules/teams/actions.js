import {
  SET_TEAM_UI_FLAG,
  CLEAR_TEAMS,
  SET_TEAMS,
  SET_TEAM_ITEM,
  EDIT_TEAM,
  DELETE_TEAM,
} from './types';
import TeamsAPI from '../../../api/teams';

export const actions = {
  create: async ({ commit }, teamInfo) => {
    commit(SET_TEAM_UI_FLAG, { isCreating: true });
    try {
      const response = await TeamsAPI.create(teamInfo);
      const team = response.data;
      commit(SET_TEAM_UI_FLAG, { isCreating: false });
      commit(SET_TEAM_ITEM, team);
      return team;
    } catch (error) {
      commit(SET_TEAM_UI_FLAG, { isCreating: false });
      throw error;
    }
  },
  get: async ({ commit }, { page = 1 } = {}) => {
    commit(SET_TEAM_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TeamsAPI.get(page);
      commit(CLEAR_TEAMS);
      commit(SET_TEAMS, data);

      commit(SET_TEAM_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(SET_TEAM_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, { id }) => {
    commit(SET_TEAM_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await TeamsAPI.show(id);
      commit(SET_TEAM_ITEM, response.data.payload);
      commit(SET_TEAM_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      commit(SET_TEAM_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },

  update: async ({ commit }, { id, ...updateObj }) => {
    commit(SET_TEAM_UI_FLAG, { isUpdating: true });
    try {
      const response = await TeamsAPI.update(id, updateObj);
      commit(EDIT_TEAM, response.data.payload);
      commit(SET_TEAM_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(SET_TEAM_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, teamId) => {
    commit(SET_TEAM_UI_FLAG, { isDeleting: true });
    try {
      await TeamsAPI.delete(teamId);
      commit(DELETE_TEAM, teamId);
      commit(SET_TEAM_UI_FLAG, { isDeleting: false });
    } catch (error) {
      commit(SET_TEAM_UI_FLAG, { isDeleting: false });
    }
  },

  setTeam({ commit }, data) {
    commit(SET_TEAM_ITEM, data);
  },
};
