import { updateMessage } from 'widget/api/contact';

const state = {
  uiFlags: {
    isUpdating: false,
  },
};

const getters = {
  getUIFlags: $state => $state.uiFlags,
};

const actions = {
  updateMessage: async ({ commit }, { email, messageId, submittedValues }) => {
    commit('toggleUpdateStatus', true);
    try {
      await updateMessage({ email, messageId, values: submittedValues });
      commit(
        'conversation/updateMessage',
        {
          id: messageId,
          content_attributes: {
            submitted_email: email,
            submitted_values: email ? null : submittedValues,
          },
        },
        { root: true }
      );
    } catch (error) {
      // Ignore error
    }
    commit('toggleUpdateStatus', false);
  },
};

const mutations = {
  toggleUpdateStatus($state, status) {
    $state.uiFlags.isUpdating = status;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
