import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
