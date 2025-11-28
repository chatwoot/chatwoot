// import * as types from '../mutation-types';
import PriorityGroupsAPI from '../../api/priorityGroups';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
  getPriorityGroup: $state => id => $state.records[Number(id)] || null,
  allPriorityGroups: $state => Object.values($state.records),
};

export const actions = {
  async get({ commit }) {
    commit('SET_PRIORITY_GROUPS_UI_FLAG', { isFetching: true });

    try {
      const response = await PriorityGroupsAPI.index();

      commit('SET_PRIORITY_GROUPS', { data: response.data });
      commit('SET_PRIORITY_GROUPS_UI_FLAG', {
        isFetching: false,
        isError: false,
      });
    } catch (error) {
      commit('SET_PRIORITY_GROUPS_UI_FLAG', {
        isFetching: false,
        isError: true,
      });
    }
  },

  setPriorityGroup({ commit }, { id, data }) {
    commit('SET_PRIORITY_GROUP', { id, data });
  },
};

export const mutations = {
  SET_PRIORITY_GROUPS_UI_FLAG($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  SET_PRIORITY_GROUPS($state, { data }) {
    const records = {};
    data.forEach(group => {
      records[group.id] = group;
    });
    $state.records = records;
  },

  SET_PRIORITY_GROUP($state, { id, data }) {
    $state.records = { ...$state.records, [id]: data };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
