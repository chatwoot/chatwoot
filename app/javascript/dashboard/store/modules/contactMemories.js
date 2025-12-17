import aiAPI from '../../api/aiFeatures';
import types from '../mutation-types';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getContactMemories: _state => contactId => {
    return _state.records[contactId] || [];
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  fetch: async ({ commit }, { accountId, contactId }) => {
    commit(types.SET_CONTACT_MEMORIES_UI_FLAG, { isFetching: true });
    try {
      const response = await aiAPI.fetchContactMemories(contactId);
      commit(types.SET_CONTACT_MEMORIES, { contactId, data: response.data });
      return response;
    } catch (error) {
      console.error('Error fetching contact memories:', error);
      throw error;
    } finally {
      commit(types.SET_CONTACT_MEMORIES_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, { accountId, contactId, memory }) => {
    try {
      const response = await aiAPI.createContactMemory(contactId, memory);
      commit(types.ADD_CONTACT_MEMORY, { contactId, data: response.data });
      return response;
    } catch (error) {
      console.error('Error creating contact memory:', error);
      throw error;
    }
  },

  search: async ({ commit }, { accountId, contactId, query }) => {
    commit(types.SET_CONTACT_MEMORIES_UI_FLAG, { isFetching: true });
    try {
      const response = await aiAPI.searchContactMemories(contactId, query);
      return response;
    } catch (error) {
      console.error('Error searching contact memories:', error);
      throw error;
    } finally {
      commit(types.SET_CONTACT_MEMORIES_UI_FLAG, { isFetching: false });
    }
  },

  update: async ({ commit }, { accountId, contactId, memoryId, data }) => {
    try {
      const response = await aiAPI.updateContactMemory(contactId, memoryId, data);
      commit(types.UPDATE_CONTACT_MEMORY, { contactId, memoryId, data: response.data });
      return response;
    } catch (error) {
      console.error('Error updating contact memory:', error);
      throw error;
    }
  },

  delete: async ({ commit }, { accountId, contactId, memoryId }) => {
    try {
      await aiAPI.deleteContactMemory(contactId, memoryId);
      commit(types.DELETE_CONTACT_MEMORY, { contactId, memoryId });
    } catch (error) {
      console.error('Error deleting contact memory:', error);
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_CONTACT_MEMORIES](_state, { contactId, data }) {
    _state.records[contactId] = data;
  },
  [types.ADD_CONTACT_MEMORY](_state, { contactId, data }) {
    if (!_state.records[contactId]) {
      _state.records[contactId] = [];
    }
    _state.records[contactId].push(data);
  },
  [types.UPDATE_CONTACT_MEMORY](_state, { contactId, memoryId, data }) {
    const memories = _state.records[contactId] || [];
    const index = memories.findIndex(m => m.id === memoryId);
    if (index !== -1) {
      memories[index] = data;
    }
  },
  [types.DELETE_CONTACT_MEMORY](_state, { contactId, memoryId }) {
    const memories = _state.records[contactId] || [];
    _state.records[contactId] = memories.filter(m => m.id !== memoryId);
  },
  [types.SET_CONTACT_MEMORIES_UI_FLAG](_state, flags) {
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
