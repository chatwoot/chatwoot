import Vue from 'vue';
import * as types from '../mutation-types';

const state = {
  records: {},
};

export const getters = {
  getConversationMetadata: $state => id => {
    return $state.records[Number(id)] || {};
  },
};

export const actions = {};

export const mutations = {
  [types.default.SET_CONVERSATION_METADATA]: ($state, { id, data }) => {
    Vue.set($state.records, id, data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
