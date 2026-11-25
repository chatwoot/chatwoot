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
    isCreating: false,
  },
  lastMessageId: null,
  // Until when the bubble of a pending conversation stays up for the message that set it: a visitor
  // message seen arriving, or the last message when a typing_off ended it. Any other message uses
  // its stored time.
  pendingTyping: null,
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
