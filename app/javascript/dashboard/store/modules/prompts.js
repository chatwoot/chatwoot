import PromptAPI from '../../api/prompts';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getPrompts($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getPromptById: $state => id => {
    // Convert both to strings for comparison to handle type mismatch
    return $state.records.find(record => String(record.id) === String(id));
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await PromptAPI.get();
      commit('SET_PROMPTS', response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },

  create: async ({ commit }, promptData) => {
    commit('SET_UI_FLAG', { isCreating: true });
    try {
      const response = await PromptAPI.create(promptData);
      commit('ADD_PROMPT', response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_UI_FLAG', { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...promptData }) => {
    commit('SET_UI_FLAG', { isUpdating: true });
    try {
      const response = await PromptAPI.update(id, promptData);
      commit('UPDATE_PROMPT', response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_UI_FLAG', { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit('SET_UI_FLAG', { isDeleting: true });
    try {
      await PromptAPI.delete(id);
      commit('DELETE_PROMPT', id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('SET_UI_FLAG', { isDeleting: false });
    }
  },
};

export const mutations = {
  SET_PROMPTS($state, data) {
    $state.records = data;
  },

  ADD_PROMPT($state, prompt) {
    $state.records.push(prompt);
  },

  UPDATE_PROMPT($state, updatedPrompt) {
    const index = $state.records.findIndex(p => p.id === updatedPrompt.id);
    if (index !== -1) {
      $state.records.splice(index, 1, updatedPrompt);
    }
  },

  DELETE_PROMPT($state, id) {
    $state.records = $state.records.filter(p => p.id !== id);
  },

  SET_UI_FLAG($state, flag) {
    $state.uiFlags = { ...$state.uiFlags, ...flag };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
