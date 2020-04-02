import MessageAPI from 'widget/api/message';
import { refreshActionCableConnector } from '../../helpers/actionCable';

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
      const {
        data: {
          contact: { pubsub_token: pubsubToken },
        },
      } = await MessageAPI.update({ email, messageId });
      commit(
        'conversation/updateMessage',
        {
          id: messageId,
          content_attributes: { submitted_email: email },
        },
        { root: true }
      );
      refreshActionCableConnector(pubsubToken);
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
