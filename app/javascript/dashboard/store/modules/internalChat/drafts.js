import InternalChatDraftsAPI from '../../../api/internalChatDrafts';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const initialState = () => ({
  records: {},
  hasFetched: false,
  uiFlags: {
    isFetching: false,
  },
});

const state = initialState();

const getters = {
  getDrafts: _state => {
    return Object.values(_state.records);
  },

  getDraftByChannelId: _state => channelId => {
    return (
      Object.values(_state.records).find(
        draft =>
          draft.internal_chat_channel_id === channelId && !draft.parent_id
      ) || null
    );
  },

  getThreadDraft: _state => (channelId, parentId) => {
    return (
      Object.values(_state.records).find(
        draft =>
          draft.internal_chat_channel_id === channelId &&
          draft.parent_id === parentId
      ) || null
    );
  },

  getThreadDraftParentIds: _state => channelId => {
    const ids = new Set();
    Object.values(_state.records).forEach(draft => {
      if (draft.internal_chat_channel_id === channelId && draft.parent_id) {
        ids.add(draft.parent_id);
      }
    });
    return ids;
  },

  getUIFlags: _state => _state.uiFlags,
};

const actions = {
  fetchDrafts: async ({ commit, state: _state }) => {
    if (_state.hasFetched) return Object.values(_state.records);

    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await InternalChatDraftsAPI.getDrafts();
      const drafts = response.data;
      commit('SET_DRAFTS', drafts);
      commit('SET_HAS_FETCHED', true);
      return drafts;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },

  saveDraft: async ({ commit }, { channelId, content, parentId }) => {
    try {
      const response = await InternalChatDraftsAPI.saveDraft(channelId, {
        content,
        parent_id: parentId,
      });
      commit('SET_DRAFT', response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  deleteDraft: async ({ commit }, { channelId, draftId, parentId }) => {
    try {
      await InternalChatDraftsAPI.deleteDraft(channelId, { parentId });
      commit('DELETE_DRAFT', draftId);
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },
};

const mutations = {
  RESET(_state) {
    Object.assign(_state, initialState());
  },
  SET_DRAFTS(_state, drafts) {
    const records = {};
    drafts.forEach(draft => {
      records[draft.id] = draft;
    });
    _state.records = records;
  },

  SET_DRAFT(_state, draft) {
    _state.records = {
      ..._state.records,
      [draft.id]: draft,
    };
  },

  DELETE_DRAFT(_state, draftId) {
    const { [draftId]: _, ...rest } = _state.records;
    _state.records = rest;
  },

  SET_HAS_FETCHED(_state, value) {
    _state.hasFetched = value;
  },

  SET_UI_FLAG(_state, flags) {
    _state.uiFlags = { ..._state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
