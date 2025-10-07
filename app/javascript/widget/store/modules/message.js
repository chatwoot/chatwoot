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
    {
      email,
      messageId,
      submittedValues,
      phone,
      orderId,
      selectedReply,
      productId,
      previousSelectedReplies,
      conversationResolved,
      assignToAgent,
      productIdForMoreInfo,
      preChatFormResponse,
    }
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
        productId,
        previousSelectedReplies,
        conversationResolved,
        assignToAgent,
        productIdForMoreInfo,
        preChatFormResponse,
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
            previous_selected_replies: previousSelectedReplies,
            user_order_id: orderId,
            product_id: productId,
            conversation_resolved: conversationResolved,
            assign_to_agent: assignToAgent,
            product_id_for_more_info: productIdForMoreInfo,
            pre_chat_form_response: preChatFormResponse,
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
