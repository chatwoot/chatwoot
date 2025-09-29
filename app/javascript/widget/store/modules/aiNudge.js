const state = {
  uiFlags: {
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  updateMessageVisibilityAndQuickReply: async (
    { commit, dispatch, getters: { getUIFlags: uiFlags } },
    { messageId, replyId, shouldShow, previousSelectedReplies = [] }
  ) => {
    if (uiFlags.isUpdating) {
      return;
    }
    commit('toggleUpdateStatus', true);
    try {
      await dispatch(
        'message/update',
        {
          messageId,
          selectedReply: replyId,
          previousSelectedReplies,
          shouldShowMessageOnChat: shouldShow,
        },
        { root: true }
      );
    } catch (error) {
      // Ignore error
      // eslint-disable-next-line no-console
      console.error('Error updating message visibility:', error);
    }
    commit('toggleUpdateStatus', false);
  },
  toggleUpdateStatus: ({ commit }, status) => {
    commit('toggleUpdateStatus', status);
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
