import aiAPI from '../../api/aiFeatures';
import types from '../mutation-types';

const state = {
  suggestions: [],
  loading: false,
};

export const getters = {
  getSuggestions(_state) {
    return _state.suggestions;
  },
  isLoading(_state) {
    return _state.loading;
  },
};

export const actions = {
  fetchSuggestions: async ({ commit }, { accountId, conversationId, limit = 5 }) => {
    commit(types.SET_CANNED_RESPONSE_SUGGESTIONS_LOADING, true);
    try {
      const response = await aiAPI.fetchCannedResponseSuggestions(conversationId, { limit });
      commit(types.SET_CANNED_RESPONSE_SUGGESTIONS, response.data);
      return response;
    } catch (error) {
      console.error('Error fetching canned response suggestions:', error);
      throw error;
    } finally {
      commit(types.SET_CANNED_RESPONSE_SUGGESTIONS_LOADING, false);
    }
  },

  submitFeedback: async ({ commit }, { accountId, feedbackData }) => {
    try {
      const response = await aiAPI.submitCannedResponseFeedback(feedbackData);
      return response;
    } catch (error) {
      console.error('Error submitting canned response feedback:', error);
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_CANNED_RESPONSE_SUGGESTIONS](_state, suggestions) {
    _state.suggestions = suggestions;
  },
  [types.SET_CANNED_RESPONSE_SUGGESTIONS_LOADING](_state, loading) {
    _state.loading = loading;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
