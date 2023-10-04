import Vue from 'vue';
import types from '../mutation-types';

import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

const state = {
  records: LocalStorage.get(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES) || {},
  inReplyTo: LocalStorage.get(LOCAL_STORAGE_KEYS.MESSAGE_IN_REPLY_TO) || {},
  replyEditorMode: REPLY_EDITOR_MODES.REPLY,
};

export const getters = {
  get: _state => key => {
    return _state.records[key] || '';
  },
  getInReplyTo: _state => key => {
    return _state.inReplyTo[key];
  },
  getReplyEditorMode: _state => _state.replyEditorMode,
};

export const actions = {
  set: async ({ commit }, { key, message }) => {
    commit(types.SET_DRAFT_MESSAGES, { key, message });
  },
  delete: ({ commit }, { key }) => {
    commit(types.SET_DRAFT_MESSAGES, { key });
  },
  setInReplyTo({ commit }, { key, inReplyTo }) {
    commit(types.SET_IN_REPLY_TO, { key, inReplyTo });
  },
  deleteInReplyTo({ commit }, { key }) {
    commit(types.REMOVE_IN_REPLY_TO, { key });
  },
  setReplyEditorMode: ({ commit }, { mode }) => {
    commit(types.SET_REPLY_EDITOR_MODE, { mode });
  },
};

export const mutations = {
  [types.SET_DRAFT_MESSAGES]($state, { key, message }) {
    Vue.set($state.records, key, message);
    LocalStorage.set(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES, $state.records);
  },
  [types.REMOVE_DRAFT_MESSAGES]($state, { key }) {
    const { [key]: draftToBeRemoved, ...updatedRecords } = $state.records;
    Vue.set($state, 'records', updatedRecords);
    LocalStorage.set(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES, $state.records);
  },
  [types.SET_IN_REPLY_TO]($state, { key, inReplyTo }) {
    Vue.set($state.inReplyTo, key, inReplyTo);
    LocalStorage.set(LOCAL_STORAGE_KEYS.MESSAGE_IN_REPLY_TO, $state.inReplyTo);
  },
  [types.REMOVE_IN_REPLY_TO]($state, { key }) {
    const { [key]: draftToBeRemoved, ...newRecords } = $state.inReplyTo;
    Vue.set($state, 'inReplyTo', newRecords);
    LocalStorage.set(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES, $state.inReplyTo);
  },
  [types.SET_REPLY_EDITOR_MODE]($state, { mode }) {
    Vue.set($state, 'replyEditorMode', mode);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
