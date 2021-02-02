import Vue from 'vue';
import {
  SET_TEAM_UI_FLAG,
  CLEAR_TEAMS,
  SET_TEAMS,
  SET_TEAM_META,
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

  [SET_TEAM_META]: ($state, data) => {
    const { count, current_page: currentPage } = data;
    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
  },

  [SET_TEAMS]: ($state, data) => {
    data.forEach(contact => {
      Vue.set($state.records, contact.id, {
        ...($state.records[contact.id] || {}),
        ...contact,
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
