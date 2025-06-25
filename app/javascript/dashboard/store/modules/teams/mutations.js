import Vue from 'vue';
import {
  SET_TEAM_UI_FLAG,
  CLEAR_TEAMS,
  SET_TEAMS,
  SET_TEAM_ITEM,
  EDIT_TEAM,
  DELETE_TEAM,
} from './types';

export const mutations = {
  [SET_TEAM_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [CLEAR_TEAMS]: $state => {
    Vue.set($state, 'records', {});
  },

  [SET_TEAMS]: ($state, data) => {
    data.forEach(team => {
      Vue.set($state.records, team.id, {
        ...($state.records[team.id] || {}),
        ...team,
      });
    });
  },

  [SET_TEAM_ITEM]: ($state, data) => {
    Vue.set($state.records, data.id, {
      ...($state.records[data.id] || {}),
      ...data,
    });
  },

  [EDIT_TEAM]: ($state, data) => {
    Vue.set($state.records, data.id, data);
  },

  [DELETE_TEAM]: ($state, teamId) => {
    const { [teamId]: toDelete, ...records } = $state.records;
    Vue.set($state, 'records', records);
  },
};
