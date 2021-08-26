import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  conversations: {
    byId: {},
    allIds: [],
    uiFlags: {
      byId: {
        // 1: { allMessagesLoaded: false, isAgentTyping: false, isFetching: false },
      },
    },
  },
  messages: {
    byId: {},
    allIds: [],
    uiFlags: {
      byId: {
        // 1: { isCreating: false, isPending: false, isDeleting: false },
      },
    },
  },
  uiFlags: {
    allConversationsLoaded: false,
    isFetching: false,
    isCreating: true,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
