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
    $state.records = {};
  },

  [SET_TEAMS]: ($state, data) => {
    const updatedRecords = { ...$state.records };
    data.forEach(team => {
      updatedRecords[team.id] = {
        ...(updatedRecords[team.id] || {}),
        ...team,
      };
    });
    $state.records = updatedRecords;
  },

  [SET_TEAM_ITEM]: ($state, data) => {
    $state.records = {
      ...$state.records,
      [data.id]: {
        ...($state.records[data.id] || {}),
        ...data,
      },
    };
  },

  [EDIT_TEAM]: ($state, data) => {
    $state.records = {
      ...$state.records,
      [data.id]: data,
    };
  },

  [DELETE_TEAM]: ($state, teamId) => {
    const { [teamId]: toDelete, ...records } = $state.records;
    $state.records = records;
  },
};
