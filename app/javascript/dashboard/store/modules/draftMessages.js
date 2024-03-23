import Vue from 'vue';
import types from '../mutation-types';
import DraftMessageApi from '../../api/inbox/draft_message';

import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

const state = {
  records: LocalStorage.get(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES) || {},
  replyEditorMode: REPLY_EDITOR_MODES.REPLY,
};

export const getters = {
  get: _state => key => {
    return _state.records[key] || '';
  },
  getReplyEditorMode: _state => _state.replyEditorMode,
};

export const actions = {
  set: async ({ commit }, { key, conversationId, message }) => {
    commit(types.SET_DRAFT_MESSAGES, { key, message });
    DraftMessageApi.updateDraft({ conversationId, message });
  },
  delete: async ({ commit }, { key, conversationId }) => {
    commit(types.SET_DRAFT_MESSAGES, { key });
    DraftMessageApi.deleteDraft(conversationId);
  },
  setReplyEditorMode: ({ commit }, { mode }) => {
    commit(types.SET_REPLY_EDITOR_MODE, { mode });
  },
  getFromRemote: async ({ commit }, { key, conversationId }) => {
    const response = await DraftMessageApi.getDraft(conversationId);
    if (response && response.data.has_draft) {
      const message = response.data.message || '';
      commit(types.SET_DRAFT_MESSAGES, { key, message });
    }
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
