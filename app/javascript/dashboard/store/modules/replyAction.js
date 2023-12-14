import Vue from 'vue';
import types from '../mutation-types';
import ReplyActionApi from '../../api/inbox/reply_action';

import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

const state = {
  records: {},
};

export const getters = {
  get: _state => key => {
    return _state.records[key] || '';
  },
};

export const actions = {
  set: async ({ commit }, {key, conversationId, action_type}) => {
    commit(types.SET_REPLY_ACTION_MODE, { key, action_type });
    ReplyActionApi.update({ conversationId, action_type });
  },
  // set: async ({ commit }, { key, conversationId, action_type }) => {
  //   commit(types.SET_REPLY_ACTION_MODE, { key, action_type });
  //   ReplyActionApi.update({ conversationId, message });
  // },
  // delete: async ({ commit }, { key, conversationId }) => {
  //   commit(types.REMOVE_REPLY_ACTION_MODE, { key });
  //   ReplyActionApi.delete(conversationId);
  // },
  // get: async ({ commit }, { key, conversationId }) => {
  //   const response = await ReplyActionApi.get(conversationId);

  //   if (response && response.data.action_type) {
  //     const action_type = response.data.action_type;
  //     commit(types.SET_REPLY_ACTION_MODE, { key, action_type });
  //   }
  // },
};

export const mutations = {
  // [types.SET_REPLY_ACTION_MODE]($state, { key, action_type }) {
  //   Vue.set($state, key, action_type);
  // },
  // [types.REMOVE_REPLY_ACTION_MODE]($state, { key }) {
  //   // Vue.set($state, key, action_type);
  // },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
