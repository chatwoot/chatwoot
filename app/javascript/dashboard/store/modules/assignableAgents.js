import Vue from 'vue';

import AssignableAgentsAPI from '../../api/assignableAgents';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
  },
};

export const types = {
  SET_ASSIGNABLE_AGENTS_UI_FLAGS: 'SET_ASSIGNABLE_AGENTS_UI_FLAGS',
  SET_ASSIGNABLE_AGENTS: 'SET_ASSIGNABLE_AGENTS',
  CLEAR_ASSIGNABLE_AGENTS: 'CLEAR_ASSIGNABLE_AGENTS',
};

export const getters = {
  getAssignableAgents: $state => {
    return $state.records.filter(record => record.confirmed);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  async fetch({ commit }, inboxIds) {
    commit(types.CLEAR_ASSIGNABLE_AGENTS);
    commit(types.SET_ASSIGNABLE_AGENTS_UI_FLAGS, { isFetching: true });
    try {
      const {
        data: { payload },
      } = await AssignableAgentsAPI.get(inboxIds);
      commit(types.SET_ASSIGNABLE_AGENTS, payload);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_ASSIGNABLE_AGENTS_UI_FLAGS, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.SET_ASSIGNABLE_AGENTS_UI_FLAGS]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_ASSIGNABLE_AGENTS]: ($state, members) => {
    Vue.set($state, 'records', members);
  },
  [types.CLEAR_ASSIGNABLE_AGENTS]: $state => {
    $state.records = [];
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
