import { updateContact } from 'widget/api/contact';

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
    await updateContact({ email, messageId });
    commit(
      'conversation/updateMessage',
      {
        id: messageId,
        content_attributes: { submitted_email: email },
      },
      { root: true }
    );
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
