import { updateContact } from 'widget/api/contact';
import { IFrameHelper } from '../../App.vue';

const state = {
  uiFlags: {
    isUpdating: false,
  },
};

const getters = {
  getUIFlags: $state => $state.uiFlags,
};

const actions = {
  updateContactAttributes: async ({ commit }, { email, messageId }) => {
    commit('toggleUpdateStatus', true);
    try {
      const response = await updateContact({ email, messageId });
      const {
        data: { token },
      } = response;
      window.authToken = token;
      IFrameHelper.sendMessage({ event: 'set_auth_token', authToken: token });
      commit(
        'conversation/updateMessage',
        {
          id: messageId,
          content_attributes: { submitted_email: email },
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
