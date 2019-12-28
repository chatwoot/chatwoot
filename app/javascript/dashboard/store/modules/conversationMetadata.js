import * as types from '../mutation-types';

const state = {
  records: {},
};

const getters = {};

const actions = {};

const mutations = {
  [types.default.SET_CONVERSATION_METADATA]: ($state, { id, data }) => {
    $state.records[id] = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
