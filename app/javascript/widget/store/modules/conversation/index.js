import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

/* const state = {
  conversations: {
    byId: {},
    allIds: [],
  },
  messages: {
    byId: {},
    allIds: [],
  },
  meta: {
    byId: {
      // 1: { allMessagesLoaded: false, isAgentTyping: false, isCreating: false },
    },
  },
  uiFlags: {
    isFetchingList: false,
  },
  activeConversationId: undefined
}; */

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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
