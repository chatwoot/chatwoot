import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import SenderListEntriesAPI from '../../api/senderListEntries';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getEntries(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getEntriesByType: _state => listType => {
    return _state.records.filter(record => record.list_type === listType);
  },
};

export const actions = {
  get: async function getEntries({ commit }) {
    commit(types.SET_SENDER_LIST_ENTRIES_UI_FLAG, { isFetching: true });
    try {
      const response = await SenderListEntriesAPI.get();
      commit(types.SET_SENDER_LIST_ENTRIES, response.data);
    } finally {
      commit(types.SET_SENDER_LIST_ENTRIES_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createEntries({ commit }, { listType, values }) {
    commit(types.SET_SENDER_LIST_ENTRIES_UI_FLAG, { isCreating: true });
    try {
      const response = await SenderListEntriesAPI.create({
        list_type: listType,
        values,
      });
      const { entries = [], errors = [] } = response.data;
      // An entry can move between lists, so upsert instead of appending.
      entries.forEach(entry => commit(types.SET_SENDER_LIST_ENTRY, entry));
      return errors;
    } finally {
      commit(types.SET_SENDER_LIST_ENTRIES_UI_FLAG, { isCreating: false });
    }
  },

  delete: async function deleteEntry({ commit }, id) {
    commit(types.SET_SENDER_LIST_ENTRIES_UI_FLAG, { isDeleting: true });
    try {
      await SenderListEntriesAPI.delete(id);
      commit(types.DELETE_SENDER_LIST_ENTRY, id);
    } finally {
      commit(types.SET_SENDER_LIST_ENTRIES_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_SENDER_LIST_ENTRIES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_SENDER_LIST_ENTRIES]: MutationHelpers.set,
  [types.SET_SENDER_LIST_ENTRY]: MutationHelpers.setSingleRecord,
  [types.DELETE_SENDER_LIST_ENTRY]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
