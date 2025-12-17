import aiAPI from '../../api/aiFeatures';
import types from '../mutation-types';

const state = {
  feedbackHistory: [],
};

export const getters = {
  getFeedbackHistory(_state) {
    return _state.feedbackHistory;
  },
};

export const actions = {
  submitFeedback: async ({ commit }, { accountId, feedbackData }) => {
    try {
      const response = await aiAPI.submitRLHFFeedback(feedbackData);
      commit(types.ADD_RLHF_FEEDBACK, response.data);
      return response;
    } catch (error) {
      console.error('Error submitting RLHF feedback:', error);
      throw error;
    }
  },
};

export const mutations = {
  [types.ADD_RLHF_FEEDBACK](_state, feedback) {
    _state.feedbackHistory.push(feedback);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
