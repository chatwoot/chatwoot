import KnowledgeBaseApi from '../../api/knowledgeBase';

const state = {
  entries: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
  },
};

export const getters = {
  getEntries: kbState => kbState.entries,
  getUIFlags: kbState => kbState.uiFlags,
};

export const actions = {
  fetchEntries: async ({ commit }) => {
    commit('setUIFlags', { isFetching: true });
    try {
      const { data } = await KnowledgeBaseApi.getEntries();
      commit('setEntries', data);
    } finally {
      commit('setUIFlags', { isFetching: false });
    }
  },

  createEntry: async ({ commit }, params) => {
    commit('setUIFlags', { isCreating: true });
    try {
      const { data } = await KnowledgeBaseApi.createEntry(params);
      commit('addEntry', data);
      return data;
    } finally {
      commit('setUIFlags', { isCreating: false });
    }
  },

  updateEntry: async ({ commit }, { id, ...params }) => {
    commit('setUIFlags', { isUpdating: true });
    try {
      const { data } = await KnowledgeBaseApi.updateEntry(id, params);
      commit('updateEntry', data);
      return data;
    } finally {
      commit('setUIFlags', { isUpdating: false });
    }
  },

  deleteEntry: async ({ commit }, id) => {
    await KnowledgeBaseApi.deleteEntry(id);
    commit('removeEntry', id);
  },
};

export const mutations = {
  setEntries($state, entries) {
    $state.entries = entries;
  },
  addEntry($state, entry) {
    $state.entries.unshift(entry);
  },
  updateEntry($state, updated) {
    const index = $state.entries.findIndex(e => e.id === updated.id);
    if (index !== -1) {
      $state.entries.splice(index, 1, updated);
    }
  },
  removeEntry($state, id) {
    $state.entries = $state.entries.filter(e => e.id !== id);
  },
  setUIFlags($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
