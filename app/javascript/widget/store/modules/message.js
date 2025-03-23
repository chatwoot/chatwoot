import MessageAPI from '../../api/message';

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
    { commit, dispatch, getters: { getUIFlags: uiFlags } },
    { email, messageId, submittedValues, phone, orderId, selectedReply }
  ) => {
    if (uiFlags.isUpdating) {
      return;
    }
    commit('toggleUpdateStatus', true);
    try {
      await MessageAPI.update({
        email,
        phone,
        messageId,
        values: submittedValues,
        orderId,
        selectedReply,
      });
      commit(
        'conversation/updateMessage',
        {
          id: messageId,
          content_attributes: {
            submitted_email: email,
            submitted_values: email ? null : submittedValues,
            user_phone_number: phone,
            selected_reply: selectedReply,
            user_order_id: orderId,
          },
        },
        { root: true }
      );
      dispatch('contacts/get', {}, { root: true });
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
