import MessageAPI from '../../api/message';
import { refreshActionCableConnector } from '../../helpers/actionCable';

const state = {
  uiFlags: {
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  update: async (
    { commit, dispatch },
    { email, messageId, submittedValues }
  ) => {
    commit('toggleUpdateStatus', true);
    try {
      const {
        data: { contact: { pubsub_token: pubsubToken } = {} },
      } = await MessageAPI.update({
        email,
        messageId,
        values: submittedValues,
      });
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
      dispatch('contacts/get', {}, { root: true });
      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      // Ignore error
    }
    commit('toggleUpdateStatus', false);
  },
};

export const mutations = {
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
