import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  conversations: {},
  meta: {
    userLastSeenAt: undefined,
  },
  uiFlags: {
    allMessagesLoaded: false,
    isFetchingList: false,
    isAgentTyping: false,
    // Last message id when an agent or bot explicitly stopped typing
    typingDismissedForMessageId: null,
    isCreating: false,
  },
  lastMessageId: null,
  pendingCustomAttributes: {},
  pendingLabels: [],
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
