import Vue from 'vue';
import types from '../mutation-types';

import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

const state = {
  records: LocalStorage.get(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES) || {},
};

export const getters = {
  get: _state => {
    return _state.records;
  },
};

export const actions = {
  set: async ({ commit }, { draftMessages }) => {
    commit(types.SET_DRAFT_MESSAGES, { draftMessages });
    LocalStorage.set(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES, draftMessages);
  },
};

export const mutations = {
  [types.SET_DRAFT_MESSAGES]($state, { draftMessages }) {
    Vue.set($state, 'records', draftMessages);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
